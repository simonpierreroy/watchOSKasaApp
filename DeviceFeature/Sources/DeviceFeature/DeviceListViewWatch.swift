//
//  DeviceListView.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/31/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import BaseUI
import Combine
import ComposableArchitecture
import DeviceClient
import Foundation
import KasaCore
import SwiftUI

#if os(watchOS)
public struct DeviceListViewWatch: View {

    private let store: Store<StateView, Action>

    public init(
        store: Store<StateView, Action>
    ) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(self.store, observe: \.isRefreshingDevices) { viewStore in
            List {
                Group {

                    ForEachStore(
                        self.store.scope(
                            state: \.devicesToDisplay,
                            action: { index, action in
                                Action.tappedDevice(index: index.parent, action: action)
                            }
                        ),
                        content: DeviceDetailViewWatch.init(store:)
                    )

                    Button {
                        viewStore.send(.tappedTurnOffAll, animation: .default)
                    } label: {
                        LoadingView(.constant(viewStore.state == .closingAll)) {
                            HStack {
                                Image(systemName: "moon.fill")
                                Text(Strings.turnOff.key, bundle: .module)
                            }
                        }
                    }
                    .foregroundColor(Color.moon).listRowPlatterColor(Color.moon.opacity(0.17))

                    Button {
                        viewStore.send(.tappedRefreshButton, animation: .default)
                    } label: {
                        HStack {
                            LoadingView(.constant(viewStore.state == .loadingDevices)) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                Text(Strings.refreshList.key, bundle: .module)
                            }
                        }
                    }
                    .foregroundColor(Color.valid).listRowPlatterColor(Color.valid.opacity(0.14))
                }
                .disabled(viewStore.state.isInFlight)

                Button {
                    viewStore.send(.tappedLogout, animation: .default)
                } label: {
                    Text(Strings.logoutApp.key, bundle: .module)
                        .foregroundColor(Color.logout)
                }
                .listRowPlatterColor(Color.logout.opacity(0.17))

            }
            .alert(
                store: self.store.scope(
                    state: \.$alert,
                    action: { .alert($0) }
                )
            )
            .onAppear {
                if case .neverLoaded = viewStore.state {
                    viewStore.send(.viewAppearReload)
                }
            }
        }
    }
}

struct DeviceDetailDataViewWatch: View {
    let action: () -> Void
    let style: (image: String, tint: Color)
    let isLoading: Bool
    let isDisabled: Bool
    let name: String

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: style.image).font(.title3)
                    .foregroundColor(style.tint)
                Text(name)
                    .multilineTextAlignment(.center)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .center) {
            HStack {
                if isLoading { ProgressView() }
            }
        }
        .disabled(isDisabled)
    }
}

struct DeviceDetailViewWatch: View {

    let store: Store<ListEntry, DeviceListViewWatch.Action.DeviceAction>

    func isDisabled(_ device: DeviceReducer.State) -> Bool {
        switch device.details {
        case .failed: return true
        case .noRelay, .status: return false
        }
    }

    var body: some View {
        IfLetStore(self.store.scope(state: \.child, action: { $0 })) { childStore in
            WithViewStore(childStore, observe: { $0 }) { viewStore in
                DeviceDetailDataViewWatch(
                    action: {
                        viewStore.send(
                            .tappedDeviceChild(index: viewStore.state.id, action: .toggleChild),
                            animation: .default
                        )
                    },
                    style: styleFor(relay: viewStore.state.relay),
                    isLoading: viewStore.state.isLoading,
                    isDisabled: false,
                    name: viewStore.state.name
                )
                .alert(
                    store: childStore.scope(
                        state: \.$alert,
                        action: { .tappedDeviceChild(index: viewStore.state.id, action: .alert($0)) }
                    )
                )
            }
        } else: {
            WithViewStore(self.store, observe: { $0 }) { viewStore in
                DeviceDetailDataViewWatch(
                    action: {
                        viewStore.send(.tapped, animation: .default)
                    },
                    style: styleFor(details: viewStore.device.details),
                    isLoading: viewStore.device.isLoading,
                    isDisabled: isDisabled(viewStore.device),
                    name: viewStore.device.name
                )
                .alert(
                    store: self.store.scope(
                        state: \.device.$alert,
                        action: { .alert($0) }
                    )
                )
            }
        }
    }
}

public struct ListEntry: Equatable, Identifiable {
    public struct DoubleID: Equatable, Hashable {
        let parent: Device.ID
        let child: Device.ID?
    }

    public init(
        device: DeviceReducer.State,
        child: DeviceChildReducer.State?
    ) {
        self.device = device
        self.child = child
    }

    public var id: DoubleID { .init(parent: self.device.id, child: self.child?.id) }
    let device: DeviceReducer.State
    let child: DeviceChildReducer.State?
}

extension DeviceListViewWatch {

    public struct StateView: Equatable {
        public init(
            alert: AlertState<DevicesReducer.Action.Alert>?,
            isRefreshingDevices: DevicesReducer.State.Loading,
            devicesToDisplay: IdentifiedArrayOf<ListEntry>
        ) {
            self.alert = alert
            self.isRefreshingDevices = isRefreshingDevices
            self.devicesToDisplay = devicesToDisplay
        }

        @PresentationState var alert: AlertState<DevicesReducer.Action.Alert>?
        let isRefreshingDevices: DevicesReducer.State.Loading
        let devicesToDisplay: IdentifiedArrayOf<ListEntry>
    }

    public enum Action {

        public enum DeviceAction {
            case alert(PresentationAction<DeviceReducer.Action.Alert>)
            case tapped
            case tappedDeviceChild(index: DeviceChildReducer.State.ID, action: DeviceChildReducer.Action)
        }

        case alert(PresentationAction<DevicesReducer.Action.Alert>)
        case tappedTurnOffAll
        case tappedLogout
        case viewAppearReload
        case tappedRefreshButton
        case tappedDevice(index: DeviceReducer.State.ID, action: DeviceAction)
    }
}

extension DeviceReducer.Action {
    public init(
        viewDetailAction: DeviceListViewWatch.Action.DeviceAction
    ) {
        switch viewDetailAction {
        case .tapped:
            self = .toggle
        case .alert(let action):
            self = .alert(action)
        case .tappedDeviceChild(index: let id, let action):
            self = .deviceChild(index: id, action: action)
        }
    }
}

extension DeviceListViewWatch.StateView {
    public init(
        devices: DevicesReducer.State
    ) {
        self.alert = devices.alert

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

extension DevicesReducer.Action {
    public init(
        deviceAction: DeviceListViewWatch.Action
    ) {
        switch deviceAction {
        case .tappedDevice(index: let idx, let action):
            let deviceDetailAction = DeviceReducer.Action.init(viewDetailAction: action)
            self = .deviceDetail(index: idx, action: deviceDetailAction)
        case .tappedLogout:
            self = .delegate(.logout)
        case .tappedRefreshButton, .viewAppearReload:
            self = .fetchFromRemote
        case .tappedTurnOffAll:
            self = .turnOffAllDevices
        case .alert(let action):
            self = .alert(action)
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
                )
                .scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            )
            .previewDisplayName("List")

            DeviceListViewWatch(
                store: Store(
                    initialState: .emptyLoading,
                    reducer: DevicesReducer()
                )
                .scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            )
            .previewDisplayName("Loading")

            DeviceListViewWatch(
                store: Store(
                    initialState: .emptyNeverLoaded,
                    reducer: DevicesReducer()
                )
                .scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            )
            .previewDisplayName("Never Loaded")

            DeviceListViewWatch(
                store: Store(
                    initialState: .oneDeviceLoaded,
                    reducer: DevicesReducer()
                )
                .scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("1 item")

            DeviceListViewWatch(
                store: Store(
                    initialState: .nDeviceLoaded(n: 5, indexFailed: [2, 4]),
                    reducer: DevicesReducer()
                )
                .scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("5 items")

            DeviceListViewWatch(
                store: Store(
                    initialState: .nDeviceLoaded(n: 5, childrenCount: 3, indexFailed: [2]),
                    reducer: DevicesReducer()
                )
                .scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Group")

            DeviceListViewWatch(
                store: Store(
                    initialState: .oneDeviceLoaded,
                    reducer: DevicesReducer()
                )
                .scope(
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
                        .dependency(
                            \.devicesClient,
                            .devicesEnvError(
                                loadError: "loadError",
                                toggleError: "toggleError",
                                getDevicesError: "getDevicesError",
                                changeDevicesError: "changeDevicesError"
                            )
                        )
                )
                .scope(
                    state: DeviceListViewWatch.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Error on item")
        }
    }
}
#endif
#endif
