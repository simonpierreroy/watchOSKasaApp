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
        SwitchStore(
            self.globalStore
                .scope(
                    state: \.userState,
                    action: AppReducer.Action.userAction
                )
        ) {
            CaseLet(state: /UserReducer.State.logout, action: UserReducer.Action.logoutUser) { logoutStore in
                UserLoginViewWatch(
                    store:
                        logoutStore
                        .scope(
                            state: UserLoginViewWatch.StateView.init(userLogoutState:),
                            action: UserLogoutReducer.Action.init(userViewAction:)
                        )
                )
            }
            CaseLet(state: /UserReducer.State.logged, action: UserReducer.Action.loggedUser) { _ in
                DeviceListViewWatch(
                    store: self.globalStore
                        .scope(
                            state: \.devicesState,
                            action: AppReducer.Action.devicesAction
                        )
                        .scope(
                            state: DeviceListViewWatch.StateView.init(devices:),
                            action: DevicesReducer.Action.init(deviceAction:)
                        )
                )
            }
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
