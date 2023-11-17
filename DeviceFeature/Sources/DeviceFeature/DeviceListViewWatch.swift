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

    private let store: Store<StateView, DevicesReducer.Action>

    public init(
        store: StoreOf<DevicesReducer>
    ) {
        self.store = store.scope(
            state: DeviceListViewWatch.StateView.init(devices:),
            action: { $0 }
        )
    }

    public var body: some View {
        WithViewStore(self.store, observe: \.isRefreshingDevices) { viewStore in
            List {
                Group {

                    ForEachStore(
                        self.store.scope(
                            state: \.devicesToDisplay,
                            action: { action in
                                DevicesReducer.Action.deviceDetail(
                                    .element(id: action.id.parent, action: action.action)
                                )
                            }
                        ),
                        content: DeviceDetailViewWatch.init(store:)
                    )

                    Button {
                        viewStore.send(.turnOffAllDevices, animation: .default)
                    } label: {
                        LoadingView(.constant(viewStore.state == .closingAll)) {
                            HStack {
                                Image(systemName: "moon.fill")
                                Text(Strings.turnOff.key, bundle: .module)
                            }
                        }
                    }
                    .foregroundColor(Color.moon).listItemTint(Color.moon.opacity(0.17))

                    Button {
                        viewStore.send(.fetchFromRemote, animation: .default)
                    } label: {
                        HStack {
                            LoadingView(.constant(viewStore.state == .loadingDevices)) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                Text(Strings.refreshList.key, bundle: .module)
                            }
                        }
                    }
                    .foregroundColor(Color.valid).listItemTint(Color.valid.opacity(0.14))
                }
                .disabled(viewStore.state.isInFlight)

                Button {
                    viewStore.send(.delegate(.logout), animation: .default)
                } label: {
                    Text(Strings.logoutApp.key, bundle: .module)
                        .foregroundColor(Color.logout)
                }
                .listItemTint(Color.logout.opacity(0.17))

            }
            .alert(
                store: self.store.scope(
                    state: \.$alert,
                    action: { .alert($0) }
                )
            )
            .onAppear {
                if case .neverLoaded = viewStore.state {
                    viewStore.send(.fetchFromRemote)
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
                StateImageView(state: style, isActive: isLoading)
                Text(name)
                    .multilineTextAlignment(.center)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .disabled(isLoading || isDisabled)
    }
}

struct DeviceDetailViewWatch: View {

    let store: Store<ListEntry, DeviceReducer.Action>

    var body: some View {
        IfLetStore(self.store.scope(state: \.child, action: { $0 })) { childStore in
            WithViewStore(childStore, observe: { $0 }) { viewStore in
                DeviceDetailDataViewWatch(
                    action: {
                        viewStore.send(
                            .deviceChild(.element(id: viewStore.state.id, action: .toggleChild)),
                            animation: .default
                        )
                    },
                    style: StateImageView.styleFor(relay: viewStore.state.relay),
                    isLoading: viewStore.state.isLoading,
                    isDisabled: false,
                    name: viewStore.state.name
                )
                .alert(
                    store: childStore.scope(
                        state: \.$alert,
                        action: { .deviceChild(.element(id: viewStore.state.id, action: .alert($0))) }
                    )
                )
            }
        } else: {
            WithViewStore(self.store, observe: { $0 }) { viewStore in
                DeviceDetailDataViewWatch(
                    action: {
                        viewStore.send(.toggle, animation: .default)
                    },
                    style: StateImageView.styleFor(details: viewStore.device.details),
                    isLoading: viewStore.device.isLoading,
                    isDisabled: viewStore.device.details.is(\.failed),
                    name: viewStore.device.name
                )
                .alert(
                    store: self.store.scope(state: \.device.$destination, action: { .destination($0) }),
                    state: \.alert,
                    action: DeviceReducer.Destination.Action.alert
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

    struct StateView: Equatable {
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
}

extension DeviceListViewWatch.StateView {
    init(
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

#if DEBUG

#Preview("List") {
    DeviceListViewWatch(
        store: Store(
            initialState: .emptyLogged,
            reducer: { DevicesReducer() }
        )
    )
}

#Preview("Loading") {
    DeviceListViewWatch(
        store: Store(
            initialState: .emptyLoading,
            reducer: { DevicesReducer() }
        )
    )
    .previewDisplayName("Loading")
}

#Preview("Never Loaded") {
    DeviceListViewWatch(
        store: Store(
            initialState: .emptyNeverLoaded,
            reducer: { DevicesReducer() }
        )
    )
}

#Preview("1 item") {
    DeviceListViewWatch(
        store: Store(
            initialState: .oneDeviceLoaded,
            reducer: { DevicesReducer() }
        )
    )
    .preferredColorScheme(.dark)
    .previewDisplayName("1 item")
}

#Preview("5 items") {
    DeviceListViewWatch(
        store: Store(
            initialState: .nDeviceLoaded(n: 5, indexFailed: [2, 4]),
            reducer: { DevicesReducer() }
        )
    )
    .preferredColorScheme(.dark)
    .previewDisplayName("5 items")
}

#Preview("Group") {
    DeviceListViewWatch(
        store: Store(
            initialState: .nDeviceLoaded(n: 5, childrenCount: 3, indexFailed: [2]),
            reducer: { DevicesReducer() }
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("1 item french") {
    DeviceListViewWatch(
        store: Store(
            initialState: .oneDeviceLoaded,
            reducer: { DevicesReducer() }
        )
    )
    .environment(\.locale, .init(identifier: "fr"))
}

#Preview("Error on item") {
    DeviceListViewWatch(
        store: Store(
            initialState: .nDeviceLoaded(n: 4),
            reducer: {
                DevicesReducer()
                    .dependency(
                        \.devicesClient,
                        .devicesEnvError(
                            loadError: "loadError",
                            toggleError: "toggleError",
                            getDevicesError: "getDevicesError",
                            changeDevicesError: "changeDevicesError"
                        )
                    )
            }
        )
    )
    .preferredColorScheme(.dark)
}
#endif
#endif
