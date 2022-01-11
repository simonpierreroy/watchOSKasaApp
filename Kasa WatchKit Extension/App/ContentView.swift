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
import AppPackage

struct ContentView: View {
    
    let store: Store<StateView, Never>
    let globalStore: Store<AppState, AppAction>
    
    init(store: Store<AppState, AppAction>) {
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
                    DeviceListViewWatch(store: self.globalStore.scope(
                        state: DeviceListViewWatch.StateView.init(appState:),
                        action: AppAction.init(deviceAction:)
                    )
                    )
                } else {
                    UserLoginViewWatch(
                        store: self.globalStore.scope(
                            state: \.userState,
                            action: AppAction.userAction
                        ).scope(
                            state: UserLoginViewWatch.StateView.init(userState:),
                            action: UserAction.init(userViewAction:)
                        )
                    )
                }
            }
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
        switch appState.userState.status {
        case  .loading , .logout:
            self.isUserLogged = false
        case .logged:
            self.isUserLogged = true
        }
    }
}


#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: Store<AppState, AppAction>.init(
                        initialState: .empty,
                        reducer: appReducer,
                        environment: AppEnv.mock)
        )
    }
}
#endif
