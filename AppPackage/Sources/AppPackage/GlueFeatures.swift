//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 10/12/22.
//

import ComposableArchitecture
import Foundation

struct GlueFeatures: ReducerProtocol {
    typealias State = AppReducer.State
    typealias Action = AppReducer.Action

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .devicesAction(.delegate(let delegated)):
            switch delegated {
            case .logout:
                return .run { send in await send(.userAction(.loggedUser(.delegate(.logout))), animation: .default) }
            }
        case .delegate, .userAction, .devicesAction: return .none
        }
    }
}
