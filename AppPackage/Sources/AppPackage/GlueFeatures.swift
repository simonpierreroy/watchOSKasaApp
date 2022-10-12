//
//  File.swift
//  
//
//  Created by Simon-Pierre Roy on 10/12/22.
//

import Foundation
import ComposableArchitecture

struct GlueFeatures: ReducerProtocol {
    typealias State = AppReducer.State
    typealias Action = AppReducer.Action
        
    func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
        switch action {
        case .devicesAction(.logout):
            return Effect(value: .userAction(.logout))
        default: return .none
        }
    }
}
