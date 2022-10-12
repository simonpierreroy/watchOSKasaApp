//
//  File.swift
//  
//
//  Created by Simon-Pierre Roy on 5/1/21.
//

import Foundation
import ComposableArchitecture
import DeviceClient
import UserClient
import Dependencies

struct AppDelegateReducer: ReducerProtocol {
    typealias State = AppReducer.State
    typealias Action = AppReducer.Action
    
    @Dependency(\.urlRouter.parse) var parse
    
    func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
        switch action {
        case .delegate(.applicationDidFinishLaunching):
            return Effect(value: .userAction(.loadSavedUser))
        case .delegate(.applicationWillResignActive), .delegate(.applicationWillTerminate):
            return Effect(value: .userAction(.save))
        case .delegate(.openURLContexts(let urls)):
            for url in urls {
                if let link = try? parse(url) {
                    switch link {
                    case .device(let deviceLink): return  Effect(value: .devicesAction(.attempDeepLink(deviceLink)))
                    }
                }
            }
            return .none
        default: return .none
        }
    }
}

