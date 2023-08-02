//
//  ExtensionDelegate.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/30/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import AppPackage
import ComposableArchitecture
import DeviceClient
import DeviceClientLive
import Foundation
import KasaCore
import UserClient
import UserClientLive
import WatchKit

final class KasaWatchAppDelegate: NSObject, WKApplicationDelegate {

    static let store = StoreOf<AppReducer>(
        initialState: .empty,
        reducer: AppReducer()._printChanges()
    )

    private static let viewStore: ViewStore<Void, AppReducer.Action> = {
        ViewStore(
            KasaWatchAppDelegate.store.scope(state: always, action: { $0 }),
            observe: { return },
            removeDuplicates: { _, _ in true }
        )
    }()

    func applicationDidFinishLaunching() {
        KasaWatchAppDelegate.viewStore.send(.delegate(.applicationDidFinishLaunching))
    }

    func applicationWillResignActive() {
        KasaWatchAppDelegate.viewStore.send(.delegate(.applicationWillResignActive))
    }
}
