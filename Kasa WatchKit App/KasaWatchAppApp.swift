//
//  KasaWatchAppApp.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/30/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Foundation
import SwiftUI
import WatchKit

@main
struct KasaWatchAppApp: App {
    @WKApplicationDelegateAdaptor private var extensionDelegate: KasaWatchAppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(store: KasaWatchAppDelegate.store)
        }
    }
}
