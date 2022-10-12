import Foundation
import ComposableArchitecture
import Combine
import Tagged
import KasaCore
import DeviceClient
import Foundation

public struct DeviceReducer: ReducerProtocol {
    
    public struct State: Equatable, Identifiable {
        
        public var isLoading: Bool = false
        public var error: String? = nil
        public var token: Token? = nil
        
        public let id: Device.Id
        public let name: String
        public var children: IdentifiedArrayOf<DeviceChildReducer.State>
        public var relay: RelayIsOn?
    }
    
    public enum Action {
        case toggle
        case didToggleChild(childId: State.ID, state: RelayIsOn)
        case send(Error)
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
                    try await send(.didToggle(state: toggleDeviceRelayState(token, state.id, nil)), animation: .default)
                } catch: { error, send in await send(.send(error)) }
            case .didToggle(let status):
                state.isLoading = false
                state.relay = status
                return .none
            case .didToggleChild(let id, let status):
                state.isLoading = false
                return .run { send in
                    await send(.deviceChild(index: id, action: .didToggleChild(state: status)), animation: .default)
                }
            case .send(let error):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
            case .errorHandled:
                state.error = nil
                return .none
            case .deviceChild(let childId, .toggleChild):
                guard let token = state.token, let child = state.children[id: childId], state.isLoading == false else { return .none }
                state.isLoading = true
                return .run { [stateId = state.id, childId = child.id] send in
                    let tog =  try await toggleDeviceRelayState(token, stateId, childId)
                    await send(.didToggleChild(childId: childId, state: tog), animation: .default)
                } catch: { error, send in await send(.send(error)) }
            case .deviceChild(_, .didToggleChild): // Child is taking care of it
                return .none
            }
        }.forEach(\.children, action: /Action.deviceChild(index:action:)) {
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
        
    public func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
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

