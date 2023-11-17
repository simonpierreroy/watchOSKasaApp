//
//  ContentView.swift
//  KasaApp
//
//  Created by Simon-Pierre Roy on 10/1/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import AppPackage
import ComposableArchitecture
import DeviceFeature
import Foundation
import KasaCore
import SwiftUI
import UserFeature

struct ContentView: View {

    private let globalStore: StoreOf<AppReducer>

    init(
        store: StoreOf<AppReducer>
    ) {
        self.globalStore = store
    }

    var body: some View {
        SwitchStore(
            self.globalStore
                .scope(
                    state: \.userState,
                    action: AppReducer.Action.userAction
                )
        ) { userState in
            switch userState {
            case .logout:
                CaseLet(/UserReducer.State.logout, action: UserReducer.Action.logoutUser) { logoutStore in
                    UserLoginViewiOS(store: logoutStore)
                }
            case .logged:
                CaseLet(/UserReducer.State.logged, action: UserReducer.Action.loggedUser) { _ in
                    DeviceListViewiOS(
                        store: self.globalStore
                            .scope(
                                state: \.devicesState,
                                action: AppReducer.Action.devicesAction
                            )
                    )
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    ContentView(
        store: Store(
            initialState: .empty,
            reducer: { AppReducer() }
        )
    )
}
#endif
