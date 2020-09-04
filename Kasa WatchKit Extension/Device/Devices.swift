//
//  Devices.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 6/2/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Foundation
import ComposableArchitecture
import Combine
import Tagged

enum DevicesAtion {
    case set(to: [DeviceSate])
    case fetchFromRemote
    case send(Error)
    case errorHandled
    case deviceDetail(index: Int, action: DeviceDetailAction)
}

struct DevicesState {
    static let empty = DevicesState(_devices: [], isLoading: .nerverLoaded, error: nil, token: nil)
    
    enum Loading {
        case nerverLoaded
        case loading
        case loaded
    }
    
    private var _devices: [DeviceSate]
    var devices: [DeviceSate] {
        get {
            _devices.map {
                var copy = $0
                copy.token = self.token
                return copy
            }
        }
        set { self._devices = newValue }
    }
    var isLoading: Loading
    var error: Error?
    var token: User.Token?
}

struct DevicesEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let backgroundQueue: AnySchedulerOf<DispatchQueue>
    let loadDevices: (User.Token) -> AnyPublisher<[DeviceSate], Error>
    let toggleDevicesState: DeviceDetailEvironment.ToggleEffect
}

extension DevicesEnvironment {
    init(appEnv: AppEnv) {
        self.mainQueue = appEnv.mainQueue
        self.backgroundQueue = appEnv.backgroundQueue
        self.loadDevices = appEnv.loadDevices
        self.toggleDevicesState = appEnv.toggleDevicesState
    }
}

let devicesReducer = Reducer<DevicesState, DevicesAtion, DevicesEnvironment> { state, action, environment in
    switch action {
    case .set(let devices):
        state.isLoading = .loaded
        state.devices = devices
        return .none
    case .fetchFromRemote:
        guard let token = state.token else { return .none }
        state.isLoading = .loading
        return environment.loadDevices(token)
            .map(DevicesAtion.set)
            .catch(DevicesAtion.send >>> Just.init)
            .receive(on: environment.mainQueue)
            .eraseToEffect()
    case .send(let error):
        state.isLoading = .loaded
        state.error = error
        return .none
    case .errorHandled:
        state.error = nil
        return .none
    case .deviceDetail: return .none
    }
}.combined(with:
    deviceDetailStateReducer.forEach(
        state: \DevicesState.devices,
        action: /DevicesAtion.deviceDetail(index:action:),
        environment: DeviceDetailEvironment.init(devicesEnv:)
    )
)

extension DevicesEnvironment {
    static func liveDevicesCall(token : User.Token) -> AnyPublisher<[DeviceSate], Error> {
        return Networking.App
            .getDevices(token: token)
            .map(\.deviceList)
            .map(map(DeviceSate.init(kasa:)))
            .eraseToAnyPublisher()
    }
}

#if DEBUG
extension DevicesEnvironment {
    static let mockDevicesEnv = DevicesEnvironment (
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        backgroundQueue: DispatchQueue.main.eraseToAnyScheduler(),
        loadDevices: { token in
            return Effect.future{ (work) in
                work(.success([
                    .init(id: "34", name: "Test device 1"),
                    .init(id: "45", name: "Test device 2")
                ]))
            }.delay(for: 2, scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
    }, toggleDevicesState: { (_,_) in
        Just(DeviceSate.RelayState.init(rawValue: true))
            .mapError(absurd)
            .delay(for: 2, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher() }
    )
}
#endif
