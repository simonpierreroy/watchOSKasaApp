//
//  Device.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/30/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Foundation
import ComposableArchitecture
import Combine
import Tagged

struct DeviceSate: Equatable, Identifiable {
    typealias Id = Tagged<DeviceSate, String>
    typealias RelayState = Tagged<DeviceSate, Bool>
    
    let id: Id
    let name: String
    var isLoading: Bool = false
    var error: String? = nil
    var token: User.Token? = nil
}

extension DeviceSate.RelayState {
    func toggle() -> Self {
        return .init(rawValue: !self.rawValue)
    }
}

extension DeviceSate {
    init(kasa: Networking.App.KasaDevice) {
        self.id = .init(rawValue: kasa.deviceId)
        self.name = kasa.alias
    }
}

enum DeviceDetailAction {
    case toggle
    case send(Error)
    case errorHandled
    case didToggle
}

struct DeviceDetailEvironment {
    typealias ToggleEffect = (User.Token, DeviceSate.ID) ->  AnyPublisher<DeviceSate.RelayState, Error>
    let toggle: ToggleEffect
    let mainQueue: AnySchedulerOf<DispatchQueue>
}

extension DeviceDetailEvironment {
    init(devicesEnv: DevicesEnvironment) {
        self.toggle = devicesEnv.toggleDevicesState
        self.mainQueue = devicesEnv.mainQueue
    }
}

extension DeviceDetailEvironment {
    static func liveToggleDeviceState(token : User.Token, id: DeviceSate.ID) -> AnyPublisher<DeviceSate.RelayState, Error> {
        return Networking.App
            .toggleDevicesState(token: token, id: id)
            .eraseToAnyPublisher()
    }
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

#if DEBUG
extension DeviceDetailEvironment {
    static let mockDetailEnv = DeviceDetailEvironment (
        toggle: { (_,_) in
            Just(DeviceSate.RelayState.init(rawValue: true))
                .mapError(absurd)
                .delay(for: 2, scheduler: DispatchQueue.main)
                .eraseToAnyPublisher() },
        mainQueue: DispatchQueue.main.eraseToAnyScheduler()
    )
}
#endif

