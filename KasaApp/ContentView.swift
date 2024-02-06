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
        switch globalStore.state.userState {
        case .logout:
            if let store = globalStore.scope(
                state: \.userState.logout,
                action: \.userAction.logoutUser
            ) {
                UserLoginViewiOS(store: store)
            }
        case .logged:
            let store = globalStore.scope(state: \.devicesState, action: \.devicesAction)
            DeviceListViewiOS(store: store)
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
