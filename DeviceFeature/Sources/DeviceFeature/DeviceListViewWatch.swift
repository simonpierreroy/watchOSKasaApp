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

    @Bindable private var store: StoreOf<DevicesReducer>

    public init(
        store: StoreOf<DevicesReducer>
    ) {
        self.store = store
    }

    public var body: some View {
        List {
            Group {
                ForEach(
                    self.store.scope(state: \.devices, action: \.deviceDetail)
                ) {
                    DeviceDetailViewWatch(store: $0)
                }

                Button {
                    store.send(.turnOffAllDevices, animation: .default)
                } label: {
                    LoadingView(store.isLoading == .closingAll) {
                        HStack {
                            Image(systemName: "moon.fill")
                            Text(Strings.turnOff.key, bundle: .module)
                        }
                    }
                }
                .foregroundColor(Color.moon).listItemTint(Color.moon.opacity(0.17))

                Button {
                    store.send(.fetchFromRemote, animation: .default)
                } label: {
                    HStack {
                        LoadingView(store.isLoading == .loadingDevices) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                            Text(Strings.refreshList.key, bundle: .module)
                        }
                    }
                }
                .foregroundColor(Color.valid).listItemTint(Color.valid.opacity(0.14))
            }
            .disabled(store.isLoading.isInFlight)

            Button {
                store.send(.delegate(.logout), animation: .default)
            } label: {
                Text(Strings.logoutApp.key, bundle: .module)
                    .foregroundColor(Color.logout)
            }
            .listItemTint(Color.logout.opacity(0.17))

        }
        .alert(
            $store.scope(state: \.alert, action: \.alert)
        )
        .onAppear {
            if case .neverLoaded = store.isLoading {
                store.send(.fetchFromRemote)
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

    init(store: StoreOf<DeviceReducer>) {
        self.store = store
    }

    @Bindable private var store: StoreOf<DeviceReducer>

    var body: some View {
        if store.children.count > 0 {
            ForEach(
                store.scope(state: \.children, action: \.deviceChild)
            ) {
                @Bindable var childStore = $0
                DeviceDetailDataViewWatch(
                    action: {
                        childStore.send(.toggleChild, animation: .default)
                    },
                    style: StateImageView.styleFor(relay: childStore.relay),
                    isLoading: childStore.isLoading,
                    isDisabled: false,
                    name: childStore.name
                )
                .alert($childStore.scope(state: \.alert, action: \.alert))
            }
        } else {
            DeviceDetailDataViewWatch(
                action: { store.send(.toggle, animation: .default) },
                style: StateImageView.styleFor(details: store.details),
                isLoading: store.isLoading,
                isDisabled: store.details.is(\.failed),
                name: store.name
            )
            .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
        }
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
