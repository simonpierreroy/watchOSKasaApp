//
//  DeviceListView.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/31/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import ComposableArchitecture
import Combine
import KasaCore
import DeviceClient

#if os(watchOS)
import SwiftUI

public struct DeviceListViewWatch: View {
    
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
                        content: DeviceDetailViewWatch.init(store:)
                    )
                    
                    
                    Button(action: { viewStore.send(.tappedCloseAll)}) {
                        HStack {
                            LoadingImage(loading: .constant(viewStore.isRefreshingDevices == .closingAll), systemName: "moon.fill")
                            Text(Strings.close_all.key, bundle: .module)
                        }
                    }
                    .foregroundColor(Color.moon).listRowPlatterColor(Color.moon.opacity(0.17))
                    
                    Button(action: { viewStore.send(.tappedRefreshButton)}) {
                        HStack {
                            LoadingImage(loading: .constant(viewStore.isRefreshingDevices == .loadingDevices), systemName: "arrow.clockwise.circle.fill")
                            Text(Strings.refresh_list.key, bundle: .module)
                        }
                    }
                    .foregroundColor(Color.valid).listRowPlatterColor(Color.valid.opacity(0.14))
                }.disabled(viewStore.isRefreshingDevices.isInFlight)
                
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

extension DeviceListViewWatch {
    struct AlertInfo: Identifiable {
        var title: String
        var id: String { self.title }
    }
}

struct DeviceDetailViewWatch: View {
    
    let store: Store<DeviceSate, DeviceListViewWatch.Action.DeviceAction>
    
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

extension DeviceDetailViewWatch {
    struct AlertInfo: Identifiable {
        var title: String
        var id: String { self.title }
    }
}

public extension DeviceListViewWatch {
    
    struct StateView: Equatable {
        public init(
            errorMessageToDisplayText: String?,
            isRefreshingDevices: DevicesState.Loading,
            devicesToDisplay: IdentifiedArrayOf<DeviceSate>
        ) {
            self.errorMessageToDisplayText = errorMessageToDisplayText
            self.isRefreshingDevices = isRefreshingDevices
            self.devicesToDisplay = devicesToDisplay
        }
        
        let errorMessageToDisplayText: String?
        let isRefreshingDevices: DevicesState.Loading
        let devicesToDisplay: IdentifiedArrayOf<DeviceSate>
    }
    
    enum Action {
        
        public enum DeviceAction {
            case tapped
            case tappedErrorAlert
        }
        
        case tappedCloseAll
        case tappedErrorAlert
        case viewAppearReload
        case tappedLogoutButton
        case tappedRefreshButton
        case tappedDevice(index: DeviceSate.ID, action: DeviceAction)
    }
}


public extension DeviceDetailAction {
    init(viewDetailAction: DeviceListViewWatch.Action.DeviceAction) {
        switch viewDetailAction {
        case .tapped:
            self = .toggle
        case .tappedErrorAlert:
            self = .errorHandled
        }
    }
}

#if DEBUG
extension DeviceListViewWatch.StateView {
    init(devices: DevicesState) {
        self.errorMessageToDisplayText = devices.error?.localizedDescription
        self.devicesToDisplay = devices.devices
        self.isRefreshingDevices = devices.isLoading
    }
}

extension DevicesAtion {
    init(deviceAction: DeviceListViewWatch.Action) {
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
        case .tappedCloseAll:
            self = .closeAll
        }
    }
}


struct DeviceListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DeviceListViewWatch(
                store: Store<DevicesState, DevicesAtion>.init(
                    initialState: DevicesState.emptyLogged,
                    reducer: devicesReducer,
                    environment: DevicesEnvironment.mockDevicesEnv
                ).scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesAtion.init(deviceAction:)
                )
            ).previewDisplayName("List")
            
            DeviceListViewWatch(
                store: Store<DevicesState, DevicesAtion>.init(
                    initialState: DevicesState.emptyLoading,
                    reducer: devicesReducer,
                    environment: DevicesEnvironment.mockDevicesEnv
                ).scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesAtion.init(deviceAction:)
                )
            ).previewDisplayName("Loading")
            
            DeviceListViewWatch(
                store: Store<DevicesState, DevicesAtion>.init(
                    initialState: DevicesState.emptyNeverLoaded,
                    reducer: devicesReducer,
                    environment: DevicesEnvironment.mockDevicesEnv
                ).scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesAtion.init(deviceAction:)
                )
            ).previewDisplayName("Never Loaded")
            
            DeviceListViewWatch(
                store: Store<DevicesState, DevicesAtion>.init(
                    initialState: DevicesState.oneDeviceLoaded,
                    reducer: devicesReducer,
                    environment: DevicesEnvironment.mockDevicesEnv
                ).scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesAtion.init(deviceAction:)
                )
            ).preferredColorScheme(.dark)
            .previewDisplayName("1 item")
            
            DeviceListViewWatch(
                store: Store<DevicesState, DevicesAtion>.init(
                    initialState: DevicesState.oneDeviceLoaded,
                    reducer: devicesReducer,
                    environment: DevicesEnvironment.mockDevicesEnv
                ).scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesAtion.init(deviceAction:)
                )
            )
            .environment(\.locale, .init(identifier: "fr"))
            .previewDisplayName("1 item french")
        }
    }
}
#endif
#endif
