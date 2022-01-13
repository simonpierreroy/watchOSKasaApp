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
    public let children: IdentifiedArrayOf<DeviceChildrenSate>
    public var relay: RelayIsOn?
}


public enum DeviceChildAction {
    case toggle
}

public enum DeviceDetailAction {
    case toggle
    case send(Error)
    case errorHandled
    case didToggle(state: RelayIsOn)
    case deviceChild(index: DeviceSate.ID, action: DeviceChildAction)
}

struct CancelInFlightToggle: Hashable {}

let deviceDetailStateReducer = Reducer<DeviceSate, DeviceDetailAction, DeviceDetailEvironment> { state, action, env in
    switch action {
    case .toggle:
        guard let token = state.token, state.relay != nil else { return .none }
        state.isLoading = true
        return env
            .toggle(token, state.id)
            .map(DeviceDetailAction.didToggle)
            .catch (DeviceDetailAction.send >>> Just.init)
            .receive(on: env.mainQueue)
            .eraseToEffect()
            .cancellable(id: CancelInFlightToggle())
    case .didToggle(let status):
        state.isLoading = false
        state.relay = status
        return .none
    case .send(let error):
        state.isLoading = false
        state.error = error.localizedDescription
        return .none
    case .errorHandled:
        state.error = nil
        return .none
    case .deviceChild:
        return .none
    }
}

