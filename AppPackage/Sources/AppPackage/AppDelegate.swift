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

public enum AppDelegateAction: Equatable {
    case applicationDidFinishLaunching
    case applicationWillTerminate
    case applicationWillResignActive
    case openURLContexts([URL])
}

let delegateReducer = Reducer<AppState, AppAction, AppEnv> { state, action, environment in
    
    switch action {
    case .delegate(.applicationDidFinishLaunching):
        return Effect(value: .userAction(.loadSavedUser))
    case .delegate(.applicationWillResignActive), .delegate(.applicationWillTerminate):
        return Effect(value: .userAction(.save))
    case .delegate(.openURLContexts(let urls)):
        for url in urls {
            if let link = try? environment.linkURLParser.parse(url) {
                switch link {
                case .device(let deviceLink): return  Effect(value: .devicesAction(.attempDeepLink(deviceLink)))
                }
            }
        }
        return .none
    default: return .none
    }
}
