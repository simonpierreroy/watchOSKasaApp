//
//  SceneDelegate.swift
//  KasaApp
//
//  Created by Simon-Pierre Roy on 10/1/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import AppPackage
import ComposableArchitecture
import DeviceClient
import DeviceFeature
import Foundation
import KasaCore
import SwiftUI
import UIKit

extension AppReducer.State {
    fileprivate var emptyState: Void { return }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {

        let contentView = ContentView(store: AppDelegate.store)

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
            SceneDelegate.parse(context: connectionOptions.urlContexts)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        SceneDelegate.parse(context: URLContexts)
    }

    static func parse(context URLContexts: Set<UIOpenURLContext>) {
        AppDelegate.store.send(
            .delegate(
                .openURLContexts(
                    URLContexts.map(\.url)
                )
            )
        )
    }
}
