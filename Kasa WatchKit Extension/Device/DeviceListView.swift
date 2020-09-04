//
//  DeviceListView.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/31/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

struct DeviceListView: View {
    
    let store: Store<StateView, Action>
    
    init(store: Store<StateView, Action>) {
        self.store = store
    }
    
    var body: some View {
        WithViewStore(self.store) { viewStore in
            List{
                Group{
                    ForEachStore(
                        self.store.scope(
                            state: \.devicesToDisplay,
                            action: Action.tappedDevice(index:action:)
                        ),
                        content: DeviceDetailView.init(store:)
                    )
                    
                    Button(action: { viewStore.send(.tappedRefreshButton)}) {
                        HStack {
                            LoadingImage(loading: .constant(viewStore.isRefreshingDevices == .loading), systemName: "arrow.clockwise.circle.fill")
                            Text("Refresh")
                        }
                    }
                }.disabled(viewStore.isRefreshingDevices == .loading)
                
                Button("Logout") { viewStore.send(.tappedLogoutButton) }
                
            }.alert(
                item: viewStore.binding(
                    get: { $0.errorMessageToDisplayText.map(AlertInfo.init(title:))},
                    send: .tappedErrorAlert
                ),
                content: { Alert(title: Text($0.title)) }
            ).onAppear{
                if case .nerverLoaded = viewStore.isRefreshingDevices {
                    viewStore.send(.viewAppearReload)
                }
            }
        }
    }
}

extension DeviceListView {
    struct AlertInfo: Identifiable {
        var title: String
        var id: String { self.title }
    }
}

struct DeviceDetailView: View {
    
    let store: Store<DeviceSate, DeviceListView.Action.DeviceAction>
    
    var body: some View {
        WithViewStore(self.store) { viewStore in
            Button(action: { viewStore.send(.tapped) }) {
                HStack {
                    LoadingImage(loading: .constant(viewStore.isLoading), systemName: "lightbulb.fill")
                    Text(viewStore.name)
                }
            }.disabled(viewStore.isLoading)
                .alert(
                    item: viewStore.binding(
                        get: { $0.error.map(AlertInfo.init(title:))},
                        send: .tappedErrorAlert
                    ),
                    content: { Alert(title: Text($0.title)) }
            )
        }
    }
}

extension DeviceDetailView {
    struct AlertInfo: Identifiable {
        var title: String
        var id: String { self.title }
    }
}

extension DeviceListView {
    
    struct StateView: Equatable {
        let errorMessageToDisplayText: String?
        let isRefreshingDevices: DevicesState.Loading
        let devicesToDisplay: [DeviceSate]
    }
    
    enum Action {
        
        enum DeviceAction {
            case tapped
            case tappedErrorAlert
        }
        
        case tappedErrorAlert
        case viewAppearReload
        case tappedLogoutButton
        case tappedRefreshButton
        case tappedDevice(index: Int, action: DeviceAction)
    }
}

extension DeviceListView.StateView {
    init(appState: AppState) {
        self.errorMessageToDisplayText = appState.devicesState.error?.localizedDescription
        self.devicesToDisplay = appState.devicesState.devices
        self.isRefreshingDevices = appState.devicesState.isLoading
    }
}

extension DeviceDetailAction {
    init(viewDetailAction: DeviceListView.Action.DeviceAction) {
        switch viewDetailAction {
        case .tapped:
            self = .toggle
        case .tappedErrorAlert:
            self = .errorHandled
        }
    }
}

extension AppAction {
    init(deviceAction: DeviceListView.Action) {
        switch deviceAction {
        case .tappedDevice(index: let idx, action: let action):
            let deviceDetailAction = DeviceDetailAction.init(viewDetailAction: action)
            self = .devicesAction(.deviceDetail(index: idx, action: deviceDetailAction))
        case .tappedErrorAlert:
            self = .devicesAction(.errorHandled)
        case .tappedLogoutButton:
            self = .userAction(.logout)
        case .tappedRefreshButton, .viewAppearReload:
            self = .devicesAction(.fetchFromRemote)
        }
    }
}

#if DEBUG

struct DeviceListView_Previews: PreviewProvider {    
    static var previews: some View {
        Group {
            DeviceListView(
                store: Store<AppState, AppAction>.init(
                    initialState: AppState.mockAppStateLoggedNotLoadingDevices,
                    reducer: appReducer,
                    environment: AppEnv.mockAppEnv
                ).scope(state: DeviceListView.StateView.init(appState:), action: AppAction.init(deviceAction:))
            ).previewDisplayName("List")
            
            DeviceListView(
                store: Store<AppState, AppAction>.init(
                    initialState: AppState.mockAppStateLoggedLoadingDevices,
                    reducer: appReducer,
                    environment: AppEnv.mockAppEnv
                ).scope(state: DeviceListView.StateView.init(appState:), action: AppAction.init(deviceAction:))
            ).previewDisplayName("List Loading")
            
            DeviceListView(
                store: Store<AppState, AppAction>.init(
                    initialState: AppState.mockAppStateLoggedNerverLoaded,
                    reducer: appReducer,
                    environment: AppEnv.mockAppEnv
                ).scope(state: DeviceListView.StateView.init(appState:), action: AppAction.init(deviceAction:))
            ).previewDisplayName("List First Load")
            
            DeviceDetailView(
                store: Store<DeviceSate, DeviceDetailAction>.init(
                    initialState: .init(
                        id: "1",
                        name: "Test",
                        token: User.Token.init(rawValue: "bbb")
                    ),
                    reducer: deviceDetailStateReducer,
                    environment: DeviceDetailEvironment.mockDetailEnv
                ).scope(
                    state: ^\DeviceSate.self,
                    action: DeviceDetailAction.init(viewDetailAction:)
                )
                )
            .previewDisplayName("Detail Preview")
        }
    }
}
#endif
