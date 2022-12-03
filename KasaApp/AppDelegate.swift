//
//  AppDelegate.swift
//  KasaApp
//
//  Created by Simon-Pierre Roy on 10/1/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import AppPackage
import ComposableArchitecture
import DeviceClient
import DeviceClientLive
import Foundation
import KasaCore
import UIKit
import UserClient
import UserClientLive

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    static let store = StoreOf<AppReducer>(
        initialState: .empty,
        reducer: AppReducer()._printChanges()
    )

    private static let viewStore: ViewStore<Void, AppReducer.Action> = {
        ViewStore(
            AppDelegate.store.scope(state: always, action: { $0 }),
            removeDuplicates: { _, _ in true }
        )
    }()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        AppDelegate.viewStore.send(.delegate(.applicationDidFinishLaunching))
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {

    }

    func applicationWillTerminate(_ application: UIApplication) {
        AppDelegate.viewStore.send(.delegate(.applicationWillTerminate))
    }
}
