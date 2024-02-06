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

extension AppReducer.State {
    fileprivate var emptyState: Void { return }
}

final class AppDelegate: UIResponder, UIApplicationDelegate {

    static let store = StoreOf<AppReducer>(
        initialState: .empty,
        reducer: { AppReducer()._printChanges() }
    )

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        AppDelegate.store.send(.delegate(.applicationDidFinishLaunching))
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Called when a new scene session is being created.

        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        if connectingSceneSession.role == .windowApplication {
            config.delegateClass = SceneDelegate.self
        }

        return config
    }

    func applicationWillTerminate(_ application: UIApplication) {
        AppDelegate.store.send(.delegate(.applicationWillTerminate))
    }
}
