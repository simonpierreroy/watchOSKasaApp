//
//  SceneDelegate.swift
//  KasaApp
//
//  Created by Simon-Pierre Roy on 10/1/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import UIKit
import SwiftUI
import DeviceFeature
import ComposableArchitecture
import AppPackage
import KasaCore
import DeviceClient

extension AppAction {
    init(delegateAction: SceneDelegate.Action) {
        switch delegateAction {
        case .deepLink(let link):
            self = AppAction.devicesAction(.attempDeepLink(link))
        }
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    enum Action {
        case deepLink(DeviceClient.Link)
    }
    
    private static let viewStore: ViewStore<Void, Action> = {
        ViewStore(
            AppDelegate.store
                .scope(
                    state: always,
                    action: AppAction.init(delegateAction:)
                ),
            removeDuplicates: { _,_ in true }
        )
    }()
    
    var window: UIWindow?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()
        
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
        for context in URLContexts{
            let link = DeviceClient.Link.parserDeepLink(url: context.url)
            if case .device = link {
                SceneDelegate.viewStore.send(.deepLink(link))
                break
            }
        }
    }
}

