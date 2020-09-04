//
//  App.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/30/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Foundation
import ComposableArchitecture
import Combine

struct AppState {
    static let empty = AppState(userState: .empty, _devicesState: .empty)
    
    var userState: UserState
    private var _devicesState: DevicesState

    var devicesState: DevicesState {
        get {
            var copy = self._devicesState
            copy.token = self.userState.user?.token
            return copy
        }
        set { self._devicesState = newValue }
    }
    
}

enum AppAction {
    case userAction(UserAction)
    case devicesAction(DevicesAtion)
}

struct AppEnv {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let backgroundQueue: AnySchedulerOf<DispatchQueue>
    let login: (Networking.App.Credential) -> AnyPublisher<User, Error>
    let cache: UserCache
    let loadDevices: (User.Token) -> AnyPublisher<[DeviceSate], Error>
    let toggleDevicesState: DeviceDetailEvironment.ToggleEffect
}

let appReducer: Reducer<AppState, AppAction, AppEnv> = userReducer
    .pullback(
        state: \.userState,
        action: /AppAction.userAction,
        environment: UserEnvironment.init(appEnv:)
).combined(with:
    devicesReducer.pullback(
        state: \.devicesState,
        action: /AppAction.devicesAction,
        environment:DevicesEnvironment.init(appEnv:)
    )
)//.debug()

#if DEBUG
extension AppState {
    static let mockAppStateLoggedNotLoadingDevices: AppState = {
        var state = AppState.empty
        state.userState.user = User.init(token: "test")
        state.devicesState.devices = [
            DeviceSate.init(id: "1", name: "Test device 1"),
        ]
        state.devicesState.isLoading = .loaded
        return state
    }()
    
    static let mockAppStateLoggedLoadingDevices: AppState = {
        var state = AppState.mockAppStateLoggedNotLoadingDevices
        state.devicesState.isLoading = .loading
        return state
    }()
    
    static let mockAppStateLoggedNerverLoaded: AppState = {
        var state = AppState.mockAppStateLoggedNotLoadingDevices
        state.devicesState.isLoading = .nerverLoaded
        return state
    }()
}

extension AppEnv {
    static let mockAppEnv = AppEnv(
        mainQueue: DevicesEnvironment.mockDevicesEnv.mainQueue,
        backgroundQueue: DevicesEnvironment.mockDevicesEnv.backgroundQueue,
        login: UserEnvironment.mockUserEnv.login,
        cache: UserEnvironment.mockUserEnv.cache,
        loadDevices: DevicesEnvironment.mockDevicesEnv.loadDevices,
        toggleDevicesState: DevicesEnvironment.mockDevicesEnv.toggleDevicesState
    )
}
#endif
