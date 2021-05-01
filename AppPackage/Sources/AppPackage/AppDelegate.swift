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
            let link = environment.linkURLParser.parse(url)
            if case .device = link {
                return  Effect(value: .devicesAction(.attempDeepLink(link)))
            }
        }
        return .none
    default: return .none
    }
}
