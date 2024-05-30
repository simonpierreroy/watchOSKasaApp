//
//  App.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/30/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Combine
import ComposableArchitecture
import DeviceClient
import DeviceClientLive
import DeviceFeature
import Foundation
import KasaCore
import RoutingClient
import RoutingClientLive
import UserClient
import UserClientLive
import UserFeature

@Reducer
public struct AppReducer {

    public init() {}

    @ObservableState
    public struct State {
        public static func empty() -> Self {
            let sharedToken: Shared<Token?> = .init(nil)
            return Self(
                userState: .empty(with: sharedToken),
                devicesState: .empty(with: sharedToken)
            )
        }

        public var userState: UserReducer.State
        public var devicesState: DevicesReducer.State
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

    public var body: some ReducerOf<Self> {
        Scope(state: \.userState, action: \.userAction) {
            UserReducer()
        }
        Scope(state: \.devicesState, action: \.devicesAction) {
            DevicesReducer()
        }
        GlueFeatures()
        AppDelegateReducer()
    }
}
