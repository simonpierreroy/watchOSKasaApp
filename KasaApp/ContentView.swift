//
//  ContentView.swift
//  KasaApp
//
//  Created by Simon-Pierre Roy on 10/1/20.
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
                    DeviceListViewiOS(store: self.globalStore.scope(
                        state: DeviceListViewiOS.StateView.init(appState:),
                        action: AppAction.init(deviceAction:)
                    )
                    )
                } else {
                    UserLoginViewiOS(
                        store: self.globalStore.scope(
                            state: \.userState,
                            action: AppAction.userAction
                        ).scope(
                            state: UserLoginViewiOS.StateView.init(userState:),
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
        self.isUserLogged = appState.userState.user != nil
    }
}


#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: Store<AppState, AppAction>.init(
                initialState: .empty,
                reducer: appReducer,
                environment: AppEnv.mock
            )
        )
    }
}
#endif
