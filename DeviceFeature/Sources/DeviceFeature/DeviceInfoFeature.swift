//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 7/8/23.
//

import Combine
import ComposableArchitecture
import Dependencies
import DeviceClient
import Foundation
import KasaCore
import Tagged

public struct DeviceInfoReducer: ReducerProtocol {

    @Dependency(\.dismiss) var dismiss
    public struct State: Equatable {
        let info: Device.Info
        let deviceName: String
    }

    public enum Action {
        case dismiss
    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .dismiss:
            return .fireAndForget { await self.dismiss(animation: .default) }
        }
    }
}
