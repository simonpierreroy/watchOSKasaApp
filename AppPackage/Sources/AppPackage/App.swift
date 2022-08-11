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
import UserClientLive
import DeviceClientLive

public struct AppState {
    public static let empty = Self(userState: .empty, _devicesState: .empty)
    
    public var userState: UserState
    private var _devicesState: DevicesState
    
    var devicesState: DevicesState {
        get {
            var copy = self._devicesState
            switch userState.status {
            case .logout, .loading:
                copy.token = nil
            case .logged(let userState):
                copy.token  = userState.user.token
            }
            return copy
        }
        set { self._devicesState = newValue }
    }
    
}

public enum AppAction {
    case delegate(AppDelegateAction)
    case userAction(UserAction)
    case devicesAction(DevicesAtion)
}


public struct AppEnv {
    let login: @Sendable (User.Credential) async throws -> User
    let userCache: UserCache
    let devicesRepo: DevicesRepo
    let deviceCache: DevicesCache
    let reloadAppExtensions: @Sendable () async -> Void
    let linkURLParser: Link.URLParser
}

public extension AppEnv {
    static let live = Self(
        login: UserEnvironment.liveLogginEffect,
        userCache: .live,
        devicesRepo: .live,
        deviceCache: .live,
        reloadAppExtensions: AppEnv.liveReloadAppExtensions,
        linkURLParser: .live
    )
}

public extension UserEnvironment {
    init(appEnv: AppEnv) {
        self.init(
            login: appEnv.login,
            cache: appEnv.userCache,
            reloadAppExtensions: appEnv.reloadAppExtensions
        )
    }
}

public extension DevicesEnvironment {
    init(appEnv: AppEnv) {
        self.init(
            repo: appEnv.devicesRepo,
            devicesCache: appEnv.deviceCache,
            reloadAppExtensions: appEnv.reloadAppExtensions
        )
    }
}

public let appReducer = Reducer<AppState, AppAction, AppEnv>.combine(
    
    delegateReducer,
    
    userReducer.pullback(
        state: \.userState,
        action: /AppAction.userAction,
        environment: UserEnvironment.init(appEnv:)
    ),
    
    devicesReducer.pullback(
        state: \.devicesState,
        action: /AppAction.devicesAction,
        environment:DevicesEnvironment.init(appEnv:)
    )
).debug()

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
        let errorMessageToDisplayText: String?
        
        switch appState.devicesState.route {
        case nil:
            errorMessageToDisplayText = nil
        case .some(.error(let error)):
            errorMessageToDisplayText = error.localizedDescription
        }
        
        self.init(
            errorMessageToDisplayText: errorMessageToDisplayText,
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
        let errorMessageToDisplayText: String?
        
        switch appState.devicesState.route {
        case nil:
            errorMessageToDisplayText = nil
        case .some(.error(let error)):
            errorMessageToDisplayText = error.localizedDescription
        }
        
        self.init(
            errorMessageToDisplayText: errorMessageToDisplayText,
            isRefreshingDevices: appState.devicesState.isLoading,
            devicesToDisplay: appState.devicesState.devices
        )
    }
}
#endif

#if DEBUG
public extension AppEnv {
    static func mock(waitFor seconds: UInt64 = 2) -> Self {
        Self(
            login: UserEnvironment.mock(waitFor: seconds).login,
            userCache: .mock,
            devicesRepo: .mock(waitFor: seconds),
            deviceCache: .mock,
            reloadAppExtensions: DevicesEnvironment.mock(waitFor: seconds).reloadAppExtensions,
            linkURLParser: .mockDeviceIdOne
        )
    }
}
#endif


#if canImport(WidgetKit)
import WidgetKit
public extension AppEnv {
    @Sendable
    static func liveReloadAppExtensions () async -> Void {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
#else
public extension AppEnv {
    @Sendable
    static func liveReloadAppExtensions () async -> Void {
        return
    }
}
#endif
