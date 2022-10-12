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
import Foundation

struct ContentView: View {
    
    let store: Store<StateView, Never>
    let globalStore: StoreOf<AppReducer>
    
    init(store: StoreOf<AppReducer>) {
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
                    DeviceListViewiOS(
                        store: self.globalStore
                            .scope(
                                state: \.devicesState,
                                action: AppReducer.Action.devicesAction
                            )
                            .scope(
                                state: DeviceListViewiOS.StateView.init(devices:),
                                action: DevicesReducer.Action.init(deviceAction:)
                            )
                    )
                } else {
                    UserLoginViewiOS(
                        store: self.globalStore.scope(
                            state: \.userState,
                            action: AppReducer.Action.userAction
                        ).scope(
                            state: UserLoginViewiOS.StateView.init(userState:),
                            action: UserReducer.Action.init(userViewAction:)
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
    init(appState: AppReducer.State) {
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
        ContentView(
            store: Store(
                initialState: .empty,
                reducer: AppReducer()
            )
        )
    }
}
#endif
