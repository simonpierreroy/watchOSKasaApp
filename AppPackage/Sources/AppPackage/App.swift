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
import RoutingClient
import RoutingClientLive

public struct AppReducer: ReducerProtocol {
    
    public init() {}
    
    public struct State {
        public static let empty = Self(userState: .empty, _devicesState: .empty)
        
        public var userState: UserReducer.State
        private var _devicesState: DevicesReducer.State
        
        public var devicesState: DevicesReducer.State {
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
    
    public enum Action {
        public enum AppDelegate: Equatable {
            case applicationDidFinishLaunching
            case applicationWillTerminate
            case applicationWillResignActive
            case openURLContexts([URL])
        }
        case delegate(AppDelegate)
        case userAction(UserReducer.Action)
        case devicesAction(DevicesReducer.Action)
    }
    
    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \State.userState, action: /Action.userAction) {
            UserReducer()
        }
        Scope(state: \State.devicesState, action: /Action.devicesAction) {
            DevicesReducer()
        }
        GlueFeatures()
        AppDelegateReducer()
    }
}
