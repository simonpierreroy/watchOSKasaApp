//
//  AppDelegate.swift
//  KasaApp
//
//  Created by Simon-Pierre Roy on 10/1/20.
//  Copyright © 2020 Simon. All rights reserved.
//


import UIKit
import ComposableArchitecture
import UserClient
import UserClientLive
import DeviceClient
import DeviceClientLive
import KasaCore
import AppPackage

extension AppAction {
    init(delegateAction: AppDelegate.Action) {
        switch delegateAction {
        case .applicationDidFinishLaunching:
            self = .userAction(.loadSavedUser)
        case .applicationWillTerminate:
            self = .userAction(.save)
        }
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static let store: Store<AppState, AppAction> = .init(
        initialState: AppState.empty,
        reducer: appReducer,
        environment: AppEnv.init(
            mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
            backgroundQueue: DispatchQueue.global(qos: .userInteractive).eraseToAnyScheduler(),
            login: UserEnvironment.liveLogginEffect,
            cache: UserCache(save: UserEnvironment.liveSave, load: UserEnvironment.liveLoadUser),
            loadDevices: DevicesEnvironment.liveDevicesCall(token:),
            toggleDevicesState: DeviceDetailEvironment.liveToggleDeviceState,
            getDevicesState: DevicesEnvironment.liveGetDevicesState(token:id:),
            changeDevicesState: DevicesEnvironment.liveChangeDevicesState(token:id:newState:)
        )
    )
    
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
    
    enum Action {
        case applicationDidFinishLaunching
        case applicationWillTerminate
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppDelegate.viewStore.send(.applicationDidFinishLaunching)
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        AppDelegate.viewStore.send(.applicationWillTerminate)
    }

}

