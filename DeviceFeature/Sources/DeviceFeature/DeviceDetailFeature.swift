import Foundation
import ComposableArchitecture
import Combine
import Tagged
import KasaCore
import DeviceClient

public struct DeviceSate: Equatable, Identifiable {
    
    public struct DeviceChildrenSate: Equatable, Identifiable {
        public var relay: RelayIsOn
        public let id: Device.Id
        public let name: String
    }
    
    public var isLoading: Bool = false
    public var error: String? = nil
    public var token: Token? = nil
    
    public let id: Device.Id
    public let name: String
    public var children: IdentifiedArrayOf<DeviceChildrenSate>
    public var relay: RelayIsOn?
}


public enum DeviceChildAction {
    case toggleChild
    case didToggleChild(state: RelayIsOn)
}

public enum DeviceDetailAction {
    case toggle
    case didToggleChild(childId: DeviceSate.ID, state: RelayIsOn)
    case send(Error)
    case errorHandled
    case didToggle(state: RelayIsOn)
    case deviceChild(index: DeviceSate.ID, action: DeviceChildAction)
}

let deviceDetailStateReducer = Reducer<DeviceSate, DeviceDetailAction, DeviceDetailEvironment> { state, action, env in
    switch action {
    case .toggle:
        guard let token = state.token, state.isLoading == false else { return .none }
        state.isLoading = true
        return .run { [state] send in
            if state.relay == nil, let firstChild = state.children.first {
                await send(.deviceChild(index: firstChild.id, action: .toggleChild), animation: .default)
            } else {
                try await send(.didToggle(state: env.toggle(token, state.id, nil)), animation: .default)
            }
        } catch: { error, send in await send(.send(error)) }
    case .didToggle(let status):
        state.isLoading = false
        state.relay = status
        return .none
    case .didToggleChild(let id, let status):
        state.isLoading = false
        return .run { [children = state.children] send in
            for childDevice in children {
                await send(.deviceChild(index: childDevice.id, action: .didToggleChild(state: status)), animation: .default)
            }
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
            let tog =  try await env.toggle(token, stateId, childId)
            await send(.didToggleChild(childId: childId, state: tog), animation: .default)
        } catch: { error, send in await send(.send(error)) }
    case .deviceChild:
        return .none
    }
}.combined(with:
            deviceChildStateReducer.forEach(
                state: \.children,
                action: /DeviceDetailAction.deviceChild(index:action:),
                environment: { _ in return }
            )
)


let deviceChildStateReducer = Reducer<DeviceSate.DeviceChildrenSate, DeviceChildAction, Void> { state, action, env in
    switch action {
    case .toggleChild:
        // parent will take care of it
        return .none
    case .didToggleChild(let status):
        state.relay = status
        return .none
    }
}

