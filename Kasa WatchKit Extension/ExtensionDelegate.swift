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


extension AppAction {
    init(delegateAction: ExtensionDelegate.Action) {
        switch delegateAction {
        case .applicationDidFinishLaunching:
            self = .userAction(.loadSavedUser)
        case .applicationWillResignActive:
            self = .userAction(.save)
        }
    }
}


class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    
    static let store: Store<AppState, AppAction> = .init(
        initialState: AppState.empty,
        reducer: appReducer,
        environment: AppEnv.init(
            mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
            backgroundQueue: DispatchQueue.global(qos: .userInteractive).eraseToAnyScheduler(),
            login: UserEnvironment.liveLogginEffect,
            userCache: .init(save: UserEnvironment.liveSave, load: UserEnvironment.liveLoadUser),
            devicesRepo: .init(
                loadDevices: DevicesEnvironment.liveDevicesCall(token:),
                toggleDevicesState: DeviceDetailEvironment.liveToggleDeviceState,
                getDevicesState: DevicesEnvironment.liveGetDevicesState(token:id:),
                changeDevicesState: DevicesEnvironment.liveChangeDevicesState(token:id:newState:)
            ),
            deviceCache: .init(save: DevicesEnvironment.liveSave(devices:), load: DevicesEnvironment.liveLoadCache),
            reloadAppExtensions: AppEnv.liveReloadAppExtensions
        )
    )
    
    private static let viewStore: ViewStore<Void, Action> = {
        ViewStore(
            ExtensionDelegate.store
                .scope(
                    state: always,
                    action: AppAction.init(delegateAction:)
                ),
            removeDuplicates: { _,_ in true }
        )
    }()
    
    enum Action {
        case applicationDidFinishLaunching
        case applicationWillResignActive
    }
    
    
    func applicationDidFinishLaunching() {
        ExtensionDelegate.viewStore.send(.applicationDidFinishLaunching)
    }
    
    func applicationWillResignActive() {
        ExtensionDelegate.viewStore.send(.applicationWillResignActive)
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
}
