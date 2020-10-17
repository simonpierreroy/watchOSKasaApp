//
//  WidgetFeature.swift
//  KasaAppWidgetExtension
//
//  Created by Simon-Pierre Roy on 10/4/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Foundation
import ComposableArchitecture
import Combine
import DeviceClient
import UserClient
import KasaCore
import DeviceClientLive
import UserClientLive

struct WidgetState {
    let user: User?
    let device: [Device]
    
}

struct WidgetEnvironment {
    let loadDevices: AnyPublisher<[Device], Error>
    let loadUser: AnyPublisher<User?, Never>
}

extension WidgetEnvironment {
    static let liveEnv = Self(
        loadDevices: DevicesEnvironment.liveLoadCache,
        loadUser: UserEnvironment.liveLoadUser
    )
}

#if DEBUG
extension WidgetEnvironment {
    static let mockEnv = Self(
        loadDevices: DevicesEnvironment.mockDevicesEnv.cache.load,
        loadUser:  UserEnvironment.mockUserEnv.cache.load
    )
}
#endif


func getCacheState(environment: WidgetEnvironment) -> AnyPublisher<WidgetState, Error> {
    return environment
        .loadUser
        .mapError(absurd)
        .zip(environment.loadDevices)
        .map(WidgetState.init(user:device:))
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
}

