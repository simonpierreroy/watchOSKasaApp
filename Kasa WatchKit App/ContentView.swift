//
//  ContentView.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/30/20.
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

    let globalStore: StoreOf<AppReducer>

    init(
        store: StoreOf<AppReducer>
    ) {
        self.globalStore = store
    }

    var body: some View {

        switch globalStore.state.userState.userLogState {
        case .logout:
            if let store = globalStore.scope(
                state: \.userState.userLogState.logout,
                action: \.userAction.logoutUser
            ) {
                UserLoginViewWatch(store: store)
            }
        case .logged:
            let store = globalStore.scope(state: \.devicesState, action: \.devicesAction)
            DeviceListViewWatch(store: store)
        }
    }
}
#if DEBUG
#Preview {
    ContentView(
        store: Store(
            initialState: .empty(),
            reducer: { AppReducer() }
        )
    )
}
#endif
