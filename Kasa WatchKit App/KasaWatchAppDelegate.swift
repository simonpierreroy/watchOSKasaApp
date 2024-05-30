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

extension AppReducer.State {
    fileprivate var emptyState: Void { return }
}

final class KasaWatchAppDelegate: NSObject, WKApplicationDelegate {

    static let store = StoreOf<AppReducer>(
        initialState: .empty(),
        reducer: { AppReducer()._printChanges() }
    )

    func applicationDidFinishLaunching() {
        KasaWatchAppDelegate.store.send(.delegate(.applicationDidFinishLaunching))
    }

    func applicationWillResignActive() {
        KasaWatchAppDelegate.store.send(.delegate(.applicationWillResignActive))
    }
}
