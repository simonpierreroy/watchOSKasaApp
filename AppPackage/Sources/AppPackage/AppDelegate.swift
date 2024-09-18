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

@Reducer
struct AppDelegateReducer: Sendable {
    typealias State = AppReducer.State
    typealias Action = AppReducer.Action

    @Dependency(\.urlRouter.parse) var parse

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .delegate(.applicationDidFinishLaunching):
            return .send(.userAction(.logoutUser(.loadSavedUser)))
        case .delegate(.applicationWillTerminate), .delegate(.applicationWillResignActive):
            return .send(.userAction(.loggedUser(.save)))
        case .delegate(.openURLContexts(let urls)):
            for url in urls {
                if let link = try? parse(url) {
                    switch link {
                    case .devices(let deviceLink):
                        return .send(.devicesAction(.attemptDeepLink(deviceLink)))
                    }
                }
            }
            return .none
        default: return .none
        }
    }
}
