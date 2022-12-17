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

    func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
        switch action {
        case .devicesAction(.logout):
            return .run { send in await send(.userAction(.loginUser(.logout)), animation: .default) }
        default: return .none
        }
    }
}
