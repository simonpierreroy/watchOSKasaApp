//
//  ContentView.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/30/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import KasaCore
import DeviceFeature
import UserFeature

//struct ContentView: View {
//    var body: some View {
//        Text("hi")
//    }
//}

struct ContentView: View {
    
    let store: Store<StateView, Never>
    let globalStore: Store<AppState, AppAction>
    
    init(store: Store<AppState, AppAction> = ExtensionDelegate.store) {
        self.globalStore = store
        self.store = store
            .scope(
                state: StateView.init(appState:),
                action: absurd(_:)
            )
    }
    
    var body: some View {
        WithViewStore(self.store) { viewStore in
            HStack {
                if viewStore.isUserLogged {
                    DeviceListView(store: self.globalStore.scope(
                        state: DeviceListView.StateView.init(appState:),
                        action: AppAction.init(deviceAction:)
                    )
                    )
                    .transition(.slide)
                } else {
                    UserLoginView(
                        store: self.globalStore.scope(
                            state: \.userState,
                            action: AppAction.userAction
                        )
                    ).transition(.slide)
                }
            }.animation(.linear(duration: 0.3))
        }
    }
}


extension ContentView {
    
    struct StateView: Equatable {
        let isUserLogged: Bool
    }
    
}

extension ContentView.StateView {
    init(appState: AppState) {
        self.isUserLogged = appState.userState.user != nil
    }
}


#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: Store<AppState, AppAction>.init(
                        initialState: .empty,
                        reducer: appReducer,
                        environment: AppEnv.mockAppEnv)
        )
    }
}
#endif
