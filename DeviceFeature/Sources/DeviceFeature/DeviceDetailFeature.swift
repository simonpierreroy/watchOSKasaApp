import Combine
import ComposableArchitecture
import DeviceClient
import Foundation
import KasaCore
import Tagged

public struct DeviceReducer: ReducerProtocol {

    public struct State: Equatable, Identifiable {

        init(
            isLoading: Bool = false,
            route: Route? = nil,
            id: Device.Id,
            name: String,
            children: [DeviceChildReducer.State],
            details: Device.State
        ) {
            self.isLoading = isLoading
            self.route = route
            self.id = id
            self.name = name
            self.details = details
            self._children = .init(uniqueElements: children)
        }

        public enum Route: Equatable {
            case error(String)
        }

        public var isLoading: Bool
        public var route: Route?
        public let id: Device.Id
        public let name: String
        public var details: Device.State

        public var token: Token? = nil

        private var _children: IdentifiedArrayOf<DeviceChildReducer.State>
        public var children: IdentifiedArrayOf<DeviceChildReducer.State> {
            get {
                return .init(
                    uniqueElements: _children.map {
                        var copy = $0
                        copy.token = self.token
                        return copy
                    }
                )
            }
            set { self._children = newValue }
        }
    }

    public enum Action {
        case toggle
        case setError(Error)
        case errorHandled
        case didToggle(state: RelayIsOn, info: Device.Info)
        case deviceChild(index: DeviceChildReducer.State.ID, action: DeviceChildReducer.Action)
    }

    @Dependency(\.devicesClient.toggleDeviceRelayState) var toggleDeviceRelayState

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .toggle:
                guard let token = state.token, state.isLoading == false,
                    case .status(_, let info) = state.details
                else { return .none }
                state.isLoading = true
                return .run { [state] send in
                    let newState = try await toggleDeviceRelayState(token, state.id, nil)
                    await send(.didToggle(state: newState, info: info), animation: .default)
                } catch: { error, send in
                    await send(.setError(error))
                }
            case .didToggle(let relay, let info):
                state.isLoading = false
                state.details = .status(relay: relay, info: info)
                return .none
            case .setError(let error):
                state.isLoading = false
                state.route = .error(error.localizedDescription)
                return .none
            case .errorHandled:
                state.route = nil
                return .none
            case .deviceChild:  // Child is taking care of it
                return .none
            }
        }
        .forEach(\.children, action: /Action.deviceChild(index:action:)) {
            DeviceChildReducer()
        }
    }
}

public struct DeviceChildReducer: ReducerProtocol {

    public enum Action {
        case didToggleChild(relay: RelayIsOn)
        case toggleChild
        case setError(Error)
        case errorHandled
    }

    public struct State: Equatable, Identifiable {

        public enum Route: Equatable {
            case error(String)
        }

        public var relay: RelayIsOn
        public let parentId: Device.Id
        public let id: Device.Id
        public var isLoading: Bool = false
        public let name: String
        public var token: Token? = nil
        public var route: Route? = nil
    }

    @Dependency(\.devicesClient.toggleDeviceRelayState) var toggleDeviceRelayState

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .toggleChild:
            guard let token = state.token, state.isLoading == false else {
                return .none
            }
            state.isLoading = true
            return .run { [parentId = state.parentId, childId = state.id] send in
                let relay = try await toggleDeviceRelayState(token, parentId, childId)
                await send(.didToggleChild(relay: relay), animation: .default)
            } catch: { error, send in
                await send(.setError(error))
            }
        case .didToggleChild(let status):
            state.isLoading = false
            state.relay = status
            return .none
        case .setError(let error):
            state.isLoading = false
            state.route = .error(error.localizedDescription)
            return .none
        case .errorHandled:
            state.route = nil
            return .none
        }
    }
}
