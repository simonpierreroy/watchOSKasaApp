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

struct WidgetState {
    let user: User?
    let device: [Device]
    
}

struct WidgetEnvironment {
    let loadDevices: AnyPublisher<[Device], Error>
    let loadUser: Effect<User?, Never>
}

func getCacheState(environment: WidgetEnvironment) -> AnyPublisher<WidgetState, Error> {
    return environment
        .loadUser
        .mapError(absurd)
        .zip(environment.loadDevices)
        .map(WidgetState.init(user:device:))
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
}

