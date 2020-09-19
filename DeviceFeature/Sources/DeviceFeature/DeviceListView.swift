//
//  DeviceListView.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/31/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import Combine
import KasaCore
import DeviceClient

public struct DeviceListView: View {
    
    let store: Store<StateView, Action>
    
    public init(store: Store<StateView, Action>) {
        self.store = store
    }
    
    public var body: some View {
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
                            Text(Strings.refresh_list.key, bundle: .module)
                        }
                    }
                    .foregroundColor(Color.valid).listRowPlatterColor(Color.valid.opacity(0.14))
                }.disabled(viewStore.isRefreshingDevices == .loading)
                
                Button {
                    viewStore.send(.tappedLogoutButton)
                } label: {
                    Text(Strings.logout_app.key, bundle: .module)
                        .foregroundColor(Color.logout)
                }.listRowPlatterColor(Color.logout.opacity(0.17))
                    
                
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

public extension DeviceListView {
    
    struct StateView: Equatable {
        public init(
            errorMessageToDisplayText: String?,
            isRefreshingDevices: DevicesState.Loading,
            devicesToDisplay: [DeviceSate]
        ) {
            self.errorMessageToDisplayText = errorMessageToDisplayText
            self.isRefreshingDevices = isRefreshingDevices
            self.devicesToDisplay = devicesToDisplay
        }
        
        let errorMessageToDisplayText: String?
        let isRefreshingDevices: DevicesState.Loading
        let devicesToDisplay: [DeviceSate]
    }
    
    enum Action {
        
        public enum DeviceAction {
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


public extension DeviceDetailAction {
    init(viewDetailAction: DeviceListView.Action.DeviceAction) {
        switch viewDetailAction {
        case .tapped:
            self = .toggle
        case .tappedErrorAlert:
            self = .errorHandled
        }
    }
}

#if DEBUG
extension DeviceListView.StateView {
    init(devices: DevicesState) {
        self.errorMessageToDisplayText = devices.error?.localizedDescription
        self.devicesToDisplay = devices.devices
        self.isRefreshingDevices = devices.isLoading
    }
}

extension DevicesAtion {
    init(deviceAction: DeviceListView.Action) {
        switch deviceAction {
        case .tappedDevice(index: let idx, action: let action):
            let deviceDetailAction = DeviceDetailAction.init(viewDetailAction: action)
            self = .deviceDetail(index: idx, action: deviceDetailAction)
        case .tappedErrorAlert:
            self = .errorHandled
        case .tappedLogoutButton:
            self = .empty
        case .tappedRefreshButton, .viewAppearReload:
            self = .fetchFromRemote
        }
    }
}


struct DeviceListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DeviceListView(
                store: Store<DevicesState, DevicesAtion>.init(
                    initialState: DevicesState.emptyLogged,
                    reducer: devicesReducer,
                    environment: DevicesEnvironment.mockDevicesEnv
                ).scope(
                    state: DeviceListView.StateView.init(devices:),
                    action: DevicesAtion.init(deviceAction:)
                )
            ).previewDisplayName("List")
            
            DeviceListView(
                store: Store<DevicesState, DevicesAtion>.init(
                    initialState: DevicesState.emptyLoading,
                    reducer: devicesReducer,
                    environment: DevicesEnvironment.mockDevicesEnv
                ).scope(
                    state: DeviceListView.StateView.init(devices:),
                    action: DevicesAtion.init(deviceAction:)
                )
            ).previewDisplayName("Loading")
            
            DeviceListView(
                store: Store<DevicesState, DevicesAtion>.init(
                    initialState: DevicesState.emptyNeverLoaded,
                    reducer: devicesReducer,
                    environment: DevicesEnvironment.mockDevicesEnv
                ).scope(
                    state: DeviceListView.StateView.init(devices:),
                    action: DevicesAtion.init(deviceAction:)
                )
            ).previewDisplayName("Never Loaded")
            
            DeviceListView(
                store: Store<DevicesState, DevicesAtion>.init(
                    initialState: DevicesState.oneDeviceLoaded,
                    reducer: devicesReducer,
                    environment: DevicesEnvironment.mockDevicesEnv
                ).scope(
                    state: DeviceListView.StateView.init(devices:),
                    action: DevicesAtion.init(deviceAction:)
                )
            ).preferredColorScheme(.dark)
            .previewDisplayName("1 item")
            
            DeviceListView(
                store: Store<DevicesState, DevicesAtion>.init(
                    initialState: DevicesState.oneDeviceLoaded,
                    reducer: devicesReducer,
                    environment: DevicesEnvironment.mockDevicesEnv
                ).scope(
                    state: DeviceListView.StateView.init(devices:),
                    action: DevicesAtion.init(deviceAction:)
                )
            )
            .environment(\.locale, .init(identifier: "fr"))
            .previewDisplayName("1 item french")
        }
    }
}
#endif
