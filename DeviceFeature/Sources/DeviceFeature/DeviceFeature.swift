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
        case errorHandled
        case deviceDetail(index: DeviceReducer.State.ID, action: DeviceReducer.Action)
        case turnOffAllDevices
        case doneTurnOffAll
        case saveDevicesToCache
        case attemptDeepLink(DevicesLink)
        case delegate(Delegate)

        public enum Delegate {
            case logout
        }
    }

    public struct State {
        public static let empty = Self(devices: [], isLoading: .neverLoaded, route: nil, token: nil)

        init(
            devices: [DeviceReducer.State],
            isLoading: Loading,
            route: Route?,
            token: Token?,
            link: DevicesLink? = nil
        ) {
            self._devices = .init(uniqueElements: devices)
            self.isLoading = isLoading
            self.route = route
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
        public var route: Route?
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
                    guard let d = state.devices[id: id], d.children[id: childId] != nil else { return .none }
                    return .task {
                        return .deviceDetail(
                            index: id,
                            action: .deviceChild(index: childId, action: .delegate(.toggleChild))
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
                        let states = IdentifiedArrayOf<DeviceReducer.State>(uniqueElements: devices)
                        await send(.set(to: states), animation: .default)
                    } catch: { error, send in
                        await send(.setError(error), animation: .default)
                    }
            case .setError(let error):
                state.isLoading = .loaded
                state.route = .error(error)
                return .none
            case .errorHandled:
                state.route = nil
                return .none
            case .turnOffAllDevices:
                guard let token = state.token, state.isLoading == .loaded else { return .none }
                state.isLoading = .closingAll
                return
                    .task { [devices = state.devices] in
                        return try await withThrowingTaskGroup(of: Void.self) { group in
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
                    } catch: {
                        return .setError($0)
                    }
                    .animation()
            case .doneTurnOffAll:
                state.isLoading = .loaded
                return .task { Action.fetchFromRemote }
            case .deviceDetail: return .none
            case .delegate(.logout):
                state.devices = []
                state.token = nil
                return .task { .saveDevicesToCache }  // Will be provide by an other feature
            }
        }
        .forEach(\.devices, action: /Action.deviceDetail(index:action:)) {
            DeviceReducer()
        }
    }
}

extension DeviceReducer.State {
    init(
        device: Device
    ) {
        self.id = device.id
        self.name = device.name
        self.details = device.details
        let tmpChildren = device.children
            .map {
                DeviceChildReducer.State.init(relay: $0.state, id: $0.id, name: $0.name)
            }
        self.children = .init(uniqueElements: tmpChildren)
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
    static let emptyLogged = Self(devices: [], isLoading: .neverLoaded, route: nil, token: "logged")
    static let emptyLoggedLink = Self(
        devices: [],
        isLoading: .neverLoaded,
        route: nil,
        token: "logged",
        link: .device(Device.debug1.id, .toggle)
    )
    static let emptyLoading = Self(devices: [], isLoading: .loadingDevices, route: nil, token: "logged")
    static let emptyNeverLoaded = Self(devices: [], isLoading: .neverLoaded, route: nil, token: "logged")
    static let oneDeviceLoaded = Self(
        devices: [.init(device: .debug1)],
        isLoading: .loaded,
        route: nil,
        token: "logged"
    )
    static func multiRoutes(parentError: String?, childError: String?) -> Self {
        Self(
            devices: [
                .init(
                    isLoading: false,
                    route: childError.map { .error($0) },
                    id: .init(rawValue: "1"),
                    name: "1",
                    children: .init(),
                    details: .noRelay(info: .mock)
                )
            ],
            isLoading: .loaded,
            route: parentError.map { .error(NSError(domain: $0, code: 1)) },
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
            route: nil,
            token: "logged"
        )
    }
}
#endif
