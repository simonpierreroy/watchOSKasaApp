//
//  ExtensionDelegate.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/30/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import WatchKit
import ComposableArchitecture
import UserClient
import UserClientLive
import DeviceClient
import DeviceClientLive
import KasaCore
import AppPackage
import Foundation

class KasaWatchAppDelegate: NSObject, WKApplicationDelegate {
    
    static let store: Store<AppState, AppAction> = .init(
        initialState: AppState.empty,
        reducer: appReducer,
        environment: .live
    )
    
    private static let viewStore: ViewStore<Void, AppAction> = {
        ViewStore(
            KasaWatchAppDelegate.store.scope(state: always, action: { $0 }),
            removeDuplicates: { _,_ in true }
        )
    }()
    
    func applicationDidFinishLaunching() {
        KasaWatchAppDelegate.viewStore.send(.delegate(.applicationDidFinishLaunching))
    }
    
    func applicationWillResignActive() {
        KasaWatchAppDelegate.viewStore.send(.delegate(.applicationWillResignActive))
    }
}
