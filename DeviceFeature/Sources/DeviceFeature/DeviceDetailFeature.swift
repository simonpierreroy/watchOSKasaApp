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
        return .task { [state] in
            if state.relay == nil, let firstChild = state.children.first {
                return .deviceChild(index: firstChild.id, action: .toggleChild)
            }
            return try await .didToggle(state: env.toggle(token, state.id, nil))
        } catch: { return .send($0) }
    case .didToggle(let status):
        state.isLoading = false
        state.relay = status
        return .none
    case .didToggleChild(let id, let status):
        state.isLoading = false
        return .run { [state] send in
            for childDevice in state.children {
                await send(.deviceChild(index: childDevice.id, action: .didToggleChild(state: status)))
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
        return .task { [state, child] in
            let tog =  try await env.toggle(token, state.id, child.id)
            return DeviceDetailAction.didToggleChild(childId: child.id, state: tog)
        } catch: { return .send($0) }
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

