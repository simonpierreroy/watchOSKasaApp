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
import BaseUI
import Foundation
import SwiftUI

#if os(watchOS)
public struct DeviceListViewWatch: View {
    
    private let store: Store<StateView, Action>
    
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
                            action: { index, action in
                                Action.tappedDevice(index: index.parent, action: action)
                            }
                        ),
                        content: DeviceDetailViewWatch.init(store:)
                    )
                    
                    Button(action: { viewStore.send(.tappedCloseAll, animation: .default)}) {
                        LoadingView(.constant(viewStore.isRefreshingDevices == .closingAll)) {
                            HStack {
                                Image(systemName: "moon.fill")
                                Text(Strings.close_all.key, bundle: .module)
                            }
                        }
                    }
                    .foregroundColor(Color.moon).listRowPlatterColor(Color.moon.opacity(0.17))
                    
                    Button(action: { viewStore.send(.tappedRefreshButton, animation: .default)}) {
                        HStack {
                            LoadingView(.constant(viewStore.isRefreshingDevices == .loadingDevices)) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                Text(Strings.refresh_list.key, bundle: .module)
                            }
                        }
                    }
                    .foregroundColor(Color.valid).listRowPlatterColor(Color.valid.opacity(0.14))
                }.disabled(viewStore.isRefreshingDevices.isInFlight)
                
                Button {
                    viewStore.send(.tappedLogoutButton, animation: .default)
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

struct AlertInfo: Identifiable {
    var title: String
    var id: String { self.title }
}

struct DeviceDetailViewWatch: View {
    
    let store: Store<ListEntry, DeviceListViewWatch.Action.DeviceAction>
    
    var body: some View {
        WithViewStore(self.store) { viewStore in
            Button(action: {
                if let child = viewStore.child {
                    viewStore.send(.tappedDeviceChild(index: child.id, action: .toggleChild), animation: .default)
                } else {
                    viewStore.send(.tapped, animation: .default)
                }
            }) {
                HStack {
                    let style = styleForRelayState(relay: viewStore.child?.relay ?? viewStore.device.relay)
                    Image(systemName: style.image).font(.title3)
                        .foregroundColor(style.taint)
                    Text(viewStore.child?.name ?? viewStore.device.name)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            }.frame(maxWidth: .infinity).overlay(alignment: .center) {
                HStack {
                    if (viewStore.device.isLoading)  { ProgressView () }
                }
            }.alert(
                item: viewStore.binding(
                    get: { $0.device.error.map(AlertInfo.init(title:))},
                    send: .tappedErrorAlert
                ),
                content: { Alert(title: Text($0.title)) }
            )
        }
    }
}


public struct ListEntry: Equatable, Identifiable  {
    public struct DoubleID: Equatable, Hashable {
        let parent: Device.ID
        let child: Device.ID?
    }
    
    public init(device: DeviceReducer.State, child: DeviceChildReducer.State?) {
        self.device = device
        self.child = child
    }
    
    public var id: DoubleID  { .init(parent: self.device.id, child: self.child?.id) }
    let device: DeviceReducer.State
    let child: DeviceChildReducer.State?
}

public extension DeviceListViewWatch {
    
    struct StateView: Equatable {
        public init(
            errorMessageToDisplayText: String?,
            isRefreshingDevices: DevicesReducer.State.Loading,
            devicesToDisplay: IdentifiedArrayOf<ListEntry>
        ) {
            self.errorMessageToDisplayText = errorMessageToDisplayText
            self.isRefreshingDevices = isRefreshingDevices
            self.devicesToDisplay = devicesToDisplay
        }
        
        let errorMessageToDisplayText: String?
        let isRefreshingDevices: DevicesReducer.State.Loading
        let devicesToDisplay: IdentifiedArrayOf<ListEntry>
    }
    
    enum Action {
        
        public enum DeviceAction {
            case tapped
            case tappedErrorAlert
            case tappedDeviceChild(index: DeviceChildReducer.State.ID, action: DeviceChildReducer.Action)
        }
        
        case tappedCloseAll
        case tappedErrorAlert
        case viewAppearReload
        case tappedLogoutButton
        case tappedRefreshButton
        case tappedDevice(index: DeviceReducer.State.ID, action: DeviceAction)
    }
}


public extension DeviceReducer.Action {
    init(viewDetailAction: DeviceListViewWatch.Action.DeviceAction) {
        switch viewDetailAction {
        case .tapped:
            self = .toggle
        case .tappedErrorAlert:
            self = .errorHandled
        case .tappedDeviceChild(index: let id, action: let action):
            self = .deviceChild(index: id, action: action)
        }
    }
}

public extension DeviceListViewWatch.StateView {
    init(devices: DevicesReducer.State) {
        switch devices.route {
        case nil:
            self.errorMessageToDisplayText = nil
        case .some(.error(let error)):
            self.errorMessageToDisplayText = error.localizedDescription
        }
        
        var entries: [ListEntry] = []
        for device in devices.devices {
            if device.children.isEmpty {
                entries.append(ListEntry(device: device, child: nil))
            } else {
                entries.append(contentsOf: device.children.map { ListEntry(device: device, child: $0) })
            }
        }
        
        self.devicesToDisplay = .init(uniqueElements: entries)
        self.isRefreshingDevices = devices.isLoading
    }
}


public extension DevicesReducer.Action {
    init(deviceAction: DeviceListViewWatch.Action) {
        switch deviceAction {
        case .tappedDevice(index: let idx, action: let action):
            let deviceDetailAction = DeviceReducer.Action.init(viewDetailAction: action)
            self = .deviceDetail(index: idx, action: deviceDetailAction)
        case .tappedErrorAlert:
            self = .errorHandled
        case .tappedLogoutButton:
            self = .logout
        case .tappedRefreshButton, .viewAppearReload:
            self = .fetchFromRemote
        case .tappedCloseAll:
            self = .closeAll
        }
    }
}

#if DEBUG
struct DeviceListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DeviceListViewWatch(
                store: Store(
                    initialState: .emptyLogged,
                    reducer: DevicesReducer()
                ).scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            ).previewDisplayName("List")
            
            DeviceListViewWatch(
                store: Store(
                    initialState: .emptyLoading,
                    reducer: DevicesReducer()
                ).scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            ).previewDisplayName("Loading")
            
            DeviceListViewWatch(
                store: Store(
                    initialState: .emptyNeverLoaded,
                    reducer: DevicesReducer()
                ).scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            ).previewDisplayName("Never Loaded")
            
            DeviceListViewWatch(
                store: Store(
                    initialState: .oneDeviceLoaded,
                    reducer: DevicesReducer()
                ).scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            ).preferredColorScheme(.dark)
                .previewDisplayName("1 item")
            
            DeviceListViewWatch(
                store: Store(
                    initialState: .nDeviceLoaded(n: 5),
                    reducer: DevicesReducer()
                ).scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            ).preferredColorScheme(.dark)
                .previewDisplayName("5 items")
            
            DeviceListViewWatch(
                store: Store(
                    initialState: .nDeviceLoaded(n: 5, childrenCount: 3),
                    reducer: DevicesReducer()
                ).scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            ).preferredColorScheme(.dark)
                .previewDisplayName("Group")
            
            DeviceListViewWatch(
                store: Store(
                    initialState: .oneDeviceLoaded,
                    reducer: DevicesReducer()
                ).scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            )
            .environment(\.locale, .init(identifier: "fr"))
            .previewDisplayName("1 item french")
            
            DeviceListViewWatch(
                store: Store(
                    initialState: .nDeviceLoaded(n: 4),
                    reducer: DevicesReducer()
                        .dependency(\.devicesClient,
                                     .devicesEnvError(
                                        loadError: "loadError",
                                        toggleError: "toggleError",
                                        getDevicesError: "getDevicesError",
                                        changeDevicesError: "changeDevicesError"
                                     )
                        )
                ).scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            ).preferredColorScheme(.dark)
                .previewDisplayName("Error on item")
        }
    }
}
#endif
#endif
