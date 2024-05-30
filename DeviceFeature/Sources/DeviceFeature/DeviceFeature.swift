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

@Reducer
public struct DevicesReducer {

    public init() {}

    public enum Action {
        case set(to: IdentifiedArrayOf<DeviceReducer.State>)
        case fetchFromRemote
        case setError(Error)
        case deviceDetail(IdentifiedActionOf<DeviceReducer>)
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

    @ObservableState
    public struct State {
        public static func empty(with sharedToken: Shared<Token?>) -> Self {
            .init(devices: [], isLoading: .neverLoaded, alert: nil, token: sharedToken)
        }

        init(
            devices: [DeviceReducer.State],
            isLoading: Loading,
            alert: AlertState<Action.Alert>?,
            link: DevicesLink? = nil,
            token: Shared<Token?>
        ) {
            self.devices = .init(uniqueElements: devices)
            self.isLoading = isLoading
            self.alert = alert
            self.linkToComplete = link
            self._token = token
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

        public var devices: IdentifiedArrayOf<DeviceReducer.State>
        public var isLoading: Loading
        public var linkToComplete: DevicesLink?
        @Presents public var alert: AlertState<Action.Alert>?
        @Shared public var token: Token?
    }

    @Dependency(\.devicesCache.save) var saveToCache
    @Dependency(\.devicesClient.changeDeviceRelayState) var changeDeviceRelayState
    @Dependency(\.devicesClient.loadDevices) var loadDevices
    @Dependency(\.reloadAppExtensions) var reloadAppExtensions

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .attemptDeepLink(let link):
                guard state.isLoading == .loaded else {
                    state.linkToComplete = link
                    return .none
                }
                defer { state.linkToComplete = nil }

                switch link {
                case .turnOffAllDevices: return .send(.turnOffAllDevices)
                case .device(let id, .toggle):
                    guard state.devices[id: id] != nil else { return .none }
                    return .send(.deviceDetail(.element(id: id, action: .toggle)))
                case .device(let id, .child(let childId, .toggle)):
                    guard let device = state.devices[id: id], device.children[id: childId] != nil else { return .none }
                    return .send(
                        .deviceDetail(
                            .element(id: id, action: .deviceChild(.element(id: childId, action: .toggleChild)))
                        )
                    )
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
                return .run { _ in
                    try await saveToCache(list)
                    await reloadAppExtensions()
                }
            case .fetchFromRemote:
                guard let token = state.token else { return .none }
                state.isLoading = .loadingDevices
                return .run { [sharedToken = state.$token] send in
                    let devices = try await loadDevices(token)
                        .map { DeviceReducer.State.init(device: $0, sharedToken: sharedToken) }
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
                    .run { [devices = state.devices] send in
                        await send(try turnOffAllDevices(devices, token: token))
                    } catch: { (error, send) in
                        await send(.setError(error))
                    }
                    .animation()
            case .doneTurnOffAll:
                state.isLoading = .loaded
                return .send(.fetchFromRemote)
            case .deviceDetail: return .none
            case .delegate(.logout):
                state = .empty(with: state.$token)
                return .send(.saveDevicesToCache)  // Will be provide by an other feature
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .forEach(\.devices, action: \.deviceDetail) {
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
        device: Device,
        sharedToken: Shared<Token?>
    ) {
        let tmpChildren = device.children.map {
            DeviceChildReducer.State.init(
                relay: $0.state,
                parentId: device.id,
                id: $0.id,
                name: $0.name,
                token: sharedToken
            )
        }

        self.init(
            id: device.id,
            name: device.name,
            children: tmpChildren,
            details: device.details,
            token: sharedToken
        )
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
