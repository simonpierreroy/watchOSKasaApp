//
//  App.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/30/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Foundation
import Combine
import UserFeature
import DeviceFeature
import DeviceClient
import UserClient
import ComposableArchitecture
import KasaCore

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
    let login: (User.Credential) -> AnyPublisher<User, Error>
    let cache: UserCache
    let loadDevices: (Token) -> AnyPublisher<[Device], Error>
    let toggleDevicesState: DeviceDetailEvironment.ToggleEffect
}

extension UserEnvironment {
    init(appEnv: AppEnv) {
        self.init(
            mainQueue: appEnv.mainQueue,
            backgroundQueue: appEnv.backgroundQueue,
            login: appEnv.login,
            cache: appEnv.cache
        )
    }
}

extension DevicesEnvironment {
    init(appEnv: AppEnv) {
        self.init(
            mainQueue: appEnv.mainQueue,
            backgroundQueue: appEnv.backgroundQueue,
            loadDevices: appEnv.loadDevices,
            toggleDevicesState: appEnv.toggleDevicesState
        )
    }
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

extension AppAction {
    init(deviceAction: DeviceListView.Action) {
        switch deviceAction {
        case .tappedDevice(index: let idx, action: let action):
            let deviceDetailAction = DeviceDetailAction.init(viewDetailAction: action)
            self = .devicesAction(.deviceDetail(index: idx, action: deviceDetailAction))
        case .tappedErrorAlert:
            self = .devicesAction(.errorHandled)
        case .tappedLogoutButton:
            self = .userAction(.logout)
        case .tappedRefreshButton, .viewAppearReload:
            self = .devicesAction(.fetchFromRemote)
        }
    }
}

extension DeviceListView.StateView {
    init(appState: AppState) {
        self.init(
            errorMessageToDisplayText: appState.devicesState.error?.localizedDescription,
            isRefreshingDevices: appState.devicesState.isLoading,
            devicesToDisplay: appState.devicesState.devices
        )
    }
}


#if DEBUG
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


