import Combine
import ComposableArchitecture
import DeviceClient
import Foundation
import KasaCore
import Tagged

public struct DeviceReducer: ReducerProtocol {

    public struct State: Equatable, Identifiable {

        public enum Route: Equatable {
            case error(String)
        }

        public var isLoading: Bool = false
        public var token: Token? = nil
        public var route: Route? = nil

        public let id: Device.Id
        public let name: String
        public var children: IdentifiedArrayOf<DeviceChildReducer.State>
        public var relay: Device.State
    }

    public enum Action {
        case toggle
        case didToggleChild(childId: State.ID, state: RelayIsOn)
        case setError(Error)
        case errorHandled
        case didToggle(state: RelayIsOn)
        case deviceChild(index: DeviceChildReducer.State.ID, action: DeviceChildReducer.Action)
    }

    @Dependency(\.devicesClient.toggleDeviceRelayState) var toggleDeviceRelayState

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .toggle:
                guard let token = state.token, state.isLoading == false else { return .none }
                state.isLoading = true
                return .run { [state] send in
                    let newState = try await toggleDeviceRelayState(token, state.id, nil)
                    await send(.didToggle(state: newState), animation: .default)
                } catch: { error, send in
                    await send(.setError(error))
                }
            case .didToggle(let status):
                state.isLoading = false
                state.relay = .relay(status)
                return .none
            case .didToggleChild(let id, let status):
                state.isLoading = false
                return .run { send in
                    await send(.deviceChild(index: id, action: .didToggleChild(state: status)), animation: .default)
                }
            case .setError(let error):
                state.isLoading = false
                state.route = .error(error.localizedDescription)
                return .none
            case .errorHandled:
                state.route = nil
                return .none
            case .deviceChild(let childId, .toggleChild):
                guard let token = state.token, let child = state.children[id: childId], state.isLoading == false else {
                    return .none
                }
                state.isLoading = true
                return .run { [stateId = state.id, childId = child.id] send in
                    let tog = try await toggleDeviceRelayState(token, stateId, childId)
                    await send(.didToggleChild(childId: childId, state: tog), animation: .default)
                } catch: { error, send in
                    await send(.setError(error))
                }
            case .deviceChild(_, .didToggleChild):  // Child is taking care of it
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
        case toggleChild
        case didToggleChild(state: RelayIsOn)
    }

    public struct State: Equatable, Identifiable {
        public var relay: RelayIsOn
        public let id: Device.Id
        public let name: String
    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .toggleChild:
            // parent will take care of it
            return .none
        case .didToggleChild(let status):
            state.relay = status
            return .none
        }
    }
}
