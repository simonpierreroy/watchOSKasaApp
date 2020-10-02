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

public struct AppState {
    public static let empty = AppState(userState: .empty, _devicesState: .empty)
    
    public var userState: UserState
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

public enum AppAction {
    case userAction(UserAction)
    case devicesAction(DevicesAtion)
}


public struct AppEnv {
    
    public init(
        mainQueue: AnySchedulerOf<DispatchQueue>,
        backgroundQueue: AnySchedulerOf<DispatchQueue>,
        login: @escaping (User.Credential) -> AnyPublisher<User, Error>,
        cache: UserCache,
        loadDevices: @escaping (Token) -> AnyPublisher<[Device], Error>,
        toggleDevicesState: @escaping DeviceDetailEvironment.ToggleEffect,
        getDevicesState: @escaping (Token, Device.ID) -> AnyPublisher<RelayIsOn, Error>,
        changeDevicesState: @escaping (Token, Device.ID, RelayIsOn) -> AnyPublisher<RelayIsOn, Error>
    ) {
        self.mainQueue = mainQueue
        self.backgroundQueue = backgroundQueue
        self.login = login
        self.cache = cache
        self.loadDevices = loadDevices
        self.toggleDevicesState = toggleDevicesState
        self.getDevicesState = getDevicesState
        self.changeDevicesState = changeDevicesState
    }
    
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let backgroundQueue: AnySchedulerOf<DispatchQueue>
    let login: (User.Credential) -> AnyPublisher<User, Error>
    let cache: UserCache
    let loadDevices: (Token) -> AnyPublisher<[Device], Error>
    let toggleDevicesState: DeviceDetailEvironment.ToggleEffect
    let getDevicesState: (Token, Device.ID) -> AnyPublisher<RelayIsOn, Error>
    let changeDevicesState: (Token, Device.ID, RelayIsOn) -> AnyPublisher<RelayIsOn, Error>
}

public extension UserEnvironment {
    init(appEnv: AppEnv) {
        self.init(
            mainQueue: appEnv.mainQueue,
            backgroundQueue: appEnv.backgroundQueue,
            login: appEnv.login,
            cache: appEnv.cache
        )
    }
}

public extension DevicesEnvironment {
    init(appEnv: AppEnv) {
        self.init(
            mainQueue: appEnv.mainQueue,
            backgroundQueue: appEnv.backgroundQueue,
            loadDevices: appEnv.loadDevices,
            toggleDevicesState: appEnv.toggleDevicesState,
            getDevicesState: appEnv.getDevicesState,
            changeDevicesState: appEnv.changeDevicesState
        )
    }
}


public let appReducer: Reducer<AppState, AppAction, AppEnv> = userReducer
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

#if os(watchOS)
public extension AppAction {
    init(deviceAction: DeviceListViewWatch.Action) {
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
        case .tappedCloseAll:
            self = .devicesAction(.closeAll)
        }
    }
}

public extension DeviceListViewWatch.StateView {
    init(appState: AppState) {
        self.init(
            errorMessageToDisplayText: appState.devicesState.error?.localizedDescription,
            isRefreshingDevices: appState.devicesState.isLoading,
            devicesToDisplay: appState.devicesState.devices
        )
    }
}
#elseif os(iOS)
public extension AppAction {
    init(deviceAction: DeviceListViewiOS.Action) {
        switch deviceAction {
        case .tappedDevice(index: let idx, action: let action):
            let deviceDetailAction = DeviceDetailAction.init(viewDetailAction: action)
            self = .devicesAction(.deviceDetail(index: idx, action: deviceDetailAction))
        case .tappedErrorAlert:
            self = .devicesAction(.errorHandled)
        case .tappedLogout:
            self = .userAction(.logout)
        case .tappedRefreshButton, .viewAppearReload:
            self = .devicesAction(.fetchFromRemote)
        case .tappedCloseAll:
            self = .devicesAction(.closeAll)
        }
    }
}

public extension DeviceListViewiOS.StateView {
    init(appState: AppState) {
        self.init(
            errorMessageToDisplayText: appState.devicesState.error?.localizedDescription,
            isRefreshingDevices: appState.devicesState.isLoading,
            devicesToDisplay: appState.devicesState.devices
        )
    }
}
#endif

#if DEBUG
public extension AppEnv {
    static let mockAppEnv = AppEnv(
        mainQueue: DevicesEnvironment.mockDevicesEnv.mainQueue,
        backgroundQueue: DevicesEnvironment.mockDevicesEnv.backgroundQueue,
        login: UserEnvironment.mockUserEnv.login,
        cache: UserEnvironment.mockUserEnv.cache,
        loadDevices: DevicesEnvironment.mockDevicesEnv.loadDevices,
        toggleDevicesState: DevicesEnvironment.mockDevicesEnv.toggleDevicesState,
        getDevicesState: DevicesEnvironment.mockDevicesEnv.getDevicesState,
        changeDevicesState: DevicesEnvironment.mockDevicesEnv.changeDevicesState
    )
}
#endif


