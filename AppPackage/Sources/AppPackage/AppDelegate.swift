//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 5/1/21.
//

import ComposableArchitecture
import Dependencies
import DeviceClient
import Foundation
import UserClient

struct AppDelegateReducer: ReducerProtocol {
    typealias State = AppReducer.State
    typealias Action = AppReducer.Action

    @Dependency(\.urlRouter.parse) var parse

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .delegate(.applicationDidFinishLaunching):
            return .task { .userAction(.logoutUser(.loadSavedUser)) }
        case .delegate(.applicationWillTerminate), .delegate(.applicationWillResignActive):
            return .task { .userAction(.loggedUser(.save)) }
        case .delegate(.openURLContexts(let urls)):
            for url in urls {
                if let link = try? parse(url) {
                    switch link {
                    case .devices(let deviceLink): return .task { .devicesAction(.attemptDeepLink(deviceLink)) }
                    }
                }
            }
            return .none
        default: return .none
        }
    }
}
