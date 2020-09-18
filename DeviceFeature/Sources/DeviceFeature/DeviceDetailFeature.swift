import Foundation
import ComposableArchitecture
import Combine
import Tagged
import KasaCore
import DeviceClient

public struct DeviceSate: Equatable, Identifiable {
    public typealias RelayState = Tagged<DeviceSate, Bool>
    
    public let id: Device.ID
    public let name: String
    public var isLoading: Bool = false
    public var error: String? = nil
    public var token: Token? = nil
}


public enum DeviceDetailAction {
    case toggle
    case send(Error)
    case errorHandled
    case didToggle
}


let deviceDetailStateReducer = Reducer<DeviceSate, DeviceDetailAction, DeviceDetailEvironment> { state, action, env in
    switch action {
    case .toggle:
        guard let token = state.token else { return .none }
        state.isLoading = true
        return env
            .toggle(token, state.id)
            .map(always)
            .map { DeviceDetailAction.didToggle }
            .catch (DeviceDetailAction.send >>> Just.init)
            .receive(on: env.mainQueue)
            .eraseToEffect()
    case .didToggle:
        state.isLoading = false
        return .none
    case .send(let error):
        state.isLoading = false
        state.error = error.localizedDescription
        return .none
    case .errorHandled:
        state.error = nil
        return .none
    }
}

