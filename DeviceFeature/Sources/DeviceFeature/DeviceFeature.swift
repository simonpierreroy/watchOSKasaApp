//
//  DeviceDetailFeature.swift
//
//
//  Created by Simon-Pierre Roy on 9/18/20.
//

import Combine
import ComposableArchitecture
import DeviceClient
import Foundation
import KasaCore
import Tagged

public struct DevicesReducer: ReducerProtocol {

    public init() {}

    public enum Action {
        case set(to: IdentifiedArrayOf<DeviceReducer.State>)
        case fetchFromRemote
        case setError(Error)
        case deviceDetail(index: DeviceReducer.State.ID, action: DeviceReducer.Action)
        case turnOffAllDevices
        case doneTurnOffAll
        case saveDevicesToCache
        case attemptDeepLink(DevicesLink)
        case delegate(Delegate)
        case alert(PresentationAction<Alert>)

        public enum Alert: Equatable {}

        public enum Delegate {
            case logout
        }
    }

    public struct State {
        public static let empty = Self(devices: [], isLoading: .neverLoaded, alert: nil, token: nil)

        init(
            devices: [DeviceReducer.State],
            isLoading: Loading,
            alert: AlertState<Action.Alert>?,
            token: Token?,
            link: DevicesLink? = nil
        ) {
            self._devices = .init(uniqueElements: devices)
            self.isLoading = isLoading
            self.alert = alert
            self.token = token
            self.linkToComplete = link
        }

        public enum Loading {
            case neverLoaded
            case loadingDevices
            case closingAll
            case loaded

            var isInFlight: Bool {
                switch self {
                case .loadingDevices, .closingAll:
                    return true
                case .loaded, .neverLoaded:
                    return false
                }
            }
        }

        private var _devices: IdentifiedArrayOf<DeviceReducer.State>
        public var devices: IdentifiedArrayOf<DeviceReducer.State> {
            get {
                return .init(
                    uniqueElements: _devices.map {
                        var copy = $0
                        copy.token = self.token
                        return copy
                    }
                )
            }
            set { self._devices = newValue }
        }

        public enum Route {
            case error(Error)
        }

        public var token: Token?
        public var isLoading: Loading
        @PresentationState public var alert: AlertState<Action.Alert>?
        public var linkToComplete: DevicesLink?
    }

    @Dependency(\.devicesCache.save) var saveToCache
    @Dependency(\.devicesClient.changeDeviceRelayState) var changeDeviceRelayState
    @Dependency(\.devicesClient.loadDevices) var loadDevices
    @Dependency(\.reloadAppExtensions) var reloadAppExtensions

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .attemptDeepLink(let link):
                guard state.isLoading == .loaded else {
                    state.linkToComplete = link
                    return .none
                }
                defer { state.linkToComplete = nil }

                switch link {
                case .turnOffAllDevices: return .task { .turnOffAllDevices }
                case .device(let id, .toggle):
                    guard state.devices[id: id] != nil else { return .none }
                    return .task { .deviceDetail(index: id, action: .toggle) }
                case .device(let id, .child(let childId, .toggle)):
                    guard let device = state.devices[id: id], device.children[id: childId] != nil else { return .none }
                    return .task {
                        return .deviceDetail(
                            index: id,
                            action: .deviceChild(index: childId, action: .toggleChild)
                        )
                    }
                }
            case .set(let devices):
                state.isLoading = .loaded
                state.devices = devices
                return .run { [linkToComplete = state.linkToComplete] send in
                    await send(.saveDevicesToCache)
                    if let link = linkToComplete {
                        await send(.attemptDeepLink(link))
                    }
                }
            case .saveDevicesToCache:
                let list = state.devices.map(Device.init(deviceState:))
                return .fireAndForget {
                    try await saveToCache(list)
                    await reloadAppExtensions()
                }
            case .fetchFromRemote:
                guard let token = state.token else { return .none }
                state.isLoading = .loadingDevices
                return
                    .run { send in
                        let devices = try await loadDevices(token).map(DeviceReducer.State.init(device:))
                        let states = IdentifiedArrayOf(uniqueElements: devices)
                        await send(.set(to: states), animation: .default)
                    } catch: { error, send in
                        await send(.setError(error), animation: .default)
                    }
            case .setError(let error):
                state.isLoading = .loaded
                state.alert = AlertState(title: { TextState(error.localizedDescription) })
                return .none
            case .alert:
                return .none
            case .turnOffAllDevices:
                guard let token = state.token, state.isLoading == .loaded else { return .none }
                state.isLoading = .closingAll
                return
                    .task { [devices = state.devices] in
                        return try await turnOffAllDevices(devices, token: token)
                    } catch: {
                        return .setError($0)
                    }
                    .animation()
            case .doneTurnOffAll:
                state.isLoading = .loaded
                return .task { Action.fetchFromRemote }
            case .deviceDetail: return .none
            case .delegate(.logout):
                state = .empty
                return .task { .saveDevicesToCache }  // Will be provide by an other feature
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
        .forEach(\.devices, action: /Action.deviceDetail(index:action:)) {
            DeviceReducer()
        }
    }

    private func turnOffAllDevices(
        _ devices: IdentifiedArrayOf<DeviceReducer.State>,
        token: Token
    ) async throws -> Action {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for device in devices {
                if case .status = device.details {
                    group.addTask { _ = try await changeDeviceRelayState(token, device.id, nil, false) }
                }
                for child in device.children {
                    group.addTask {
                        _ = try await changeDeviceRelayState(token, device.id, child.id, false)
                    }
                }
            }
            try await group.waitForAll()
            return .doneTurnOffAll
        }
    }
}

extension DeviceReducer.State {
    init(
        device: Device
    ) {
        let tmpChildren = device.children.map {
            DeviceChildReducer.State.init(relay: $0.state, parentId: device.id, id: $0.id, name: $0.name)
        }

        self.init(id: device.id, name: device.name, children: tmpChildren, details: device.details)
    }
}

extension Device {
    init(
        deviceState: DeviceReducer.State
    ) {
        self.init(
            id: deviceState.id,
            name: deviceState.name,
            children: deviceState.children
                .map { Device.DeviceChild.init(id: $0.id, name: $0.name, state: $0.relay) },
            details: deviceState.details
        )
    }
}

#if DEBUG
extension DevicesReducer.State {
    static let emptyLogged = Self(devices: [], isLoading: .neverLoaded, alert: nil, token: "logged")
    static let emptyLoggedLink = Self(
        devices: [],
        isLoading: .neverLoaded,
        alert: nil,
        token: "logged",
        link: .device(Device.debug1.id, .toggle)
    )
    static let emptyLoading = Self(devices: [], isLoading: .loadingDevices, alert: nil, token: "logged")
    static let emptyNeverLoaded = Self(devices: [], isLoading: .neverLoaded, alert: nil, token: "logged")
    static let oneDeviceLoaded = Self(
        devices: [.init(device: .debug1)],
        isLoading: .loaded,
        alert: nil,
        token: "logged"
    )
    static func multiRoutes(parentError: String?, childError: String?) -> Self {
        Self(
            devices: [
                .init(
                    isLoading: false,
                    alert: childError.map { .init(title: TextState($0)) },
                    id: .init(rawValue: "1"),
                    name: "1",
                    children: .init(),
                    details: .noRelay(info: .mock)
                )
            ],
            isLoading: .loaded,
            alert: parentError.map { .init(title: TextState($0)) },
            token: "logged",
            link: nil
        )
    }

    static func nDeviceLoaded(n: Int, childrenCount: Int = 0, indexFailed: [Int] = []) -> Self {
        var children: [Device.DeviceChild] = []
        var state: Device.State = .status(relay: false, info: .mock)

        if childrenCount >= 1 {
            children = (1...childrenCount)
                .map { Device.DeviceChild(id: "child \($0)", name: "child \($0)", state: true) }
            state = .noRelay(info: .mock)
        }

        return Self(
            devices: (1...n)
                .map {
                    DeviceReducer.State(
                        device: .init(
                            id: "\($0)",
                            name: "Test device number \($0)",
                            children: children,
                            details: indexFailed.contains($0) ? .failed(.init(code: -1, message: "Error")) : state
                        )
                    )
                },
            isLoading: .loaded,
            alert: nil,
            token: "logged"
        )
    }
}
#endif
