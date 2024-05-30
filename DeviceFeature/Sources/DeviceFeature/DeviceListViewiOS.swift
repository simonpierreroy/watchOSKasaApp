//
//  SwiftUIView.swift
//
//
//  Created by Simon-Pierre Roy on 10/1/20.
//

import BaseUI
import CasePaths
import Combine
import ComposableArchitecture
import DeviceClient
import Foundation
import KasaCore
import SwiftUI

#if os(iOS)

public struct DeviceListViewiOS: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

    @Bindable private var store: StoreOf<DevicesReducer>

    public init(
        store: StoreOf<DevicesReducer>
    ) {
        self.store = store
    }

    public var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                NavigationStack {
                    DeviceListViewBase(store: store)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    store.send(.delegate(.logout), animation: .default)
                                } label: {
                                    Text(Strings.logoutApp.key, bundle: .module)
                                        .foregroundColor(Color.logout)
                                }
                            }
                        }

                }
            } else {
                NavigationSplitView {
                    DeviceListViewSideBar(store: store)
                } detail: {
                    DeviceListViewBase(store: store)
                }
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}

private struct DeviceListViewSideBar: View {

    private enum ListSideBar: CaseIterable, Hashable, Identifiable {
        case refresh
        case turnOffAll
        case logout

        var id: Int {
            self.hashValue
        }
    }

    private let store: StoreOf<DevicesReducer>
    init(
        store: StoreOf<DevicesReducer>
    ) {
        self.store = store
    }

    private func imageColor(_ loading: Bool) -> Color {
        loading ? Color.gray : Color.logout
    }

    public var body: some View {
        List(ListSideBar.allCases) { tab in
            switch tab {
            case .refresh:
                Button {
                    store.send(.fetchFromRemote, animation: .default)
                } label: {
                    LoadingView(store.isLoading == .loadingDevices) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundColor(imageColor(store.isLoading.isInFlight))
                            Text(Strings.refreshList.key, bundle: .module)
                        }
                    }
                }
            case .logout:
                Button {
                    store.send(.delegate(.logout), animation: .default)
                } label: {
                    HStack {
                        Image(systemName: "book.closed.fill")
                            .foregroundColor(imageColor(store.isLoading.isInFlight))
                        Text(Strings.logoutApp.key, bundle: .module)
                    }
                }
            case .turnOffAll:
                Button {
                    store.send(.turnOffAllDevices, animation: .default)
                } label: {
                    LoadingView(store.isLoading == .closingAll) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(imageColor(store.isLoading.isInFlight))
                            Text(Strings.turnOff.key, bundle: .module)
                        }
                    }
                }
            }
        }
        .listStyle(SidebarListStyle())
        .disabled(store.isLoading.isInFlight)
        .navigationTitle(Text(Strings.kasaName.key, bundle: .module))
    }
}

private struct DeviceListViewBase: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

    private let store: StoreOf<DevicesReducer>

    public init(
        store: StoreOf<DevicesReducer>
    ) {
        self.store = store
    }

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(
                    // Create stores on the main thread since lazy grid can be rendered on background
                    Array(self.store.scope(state: \.devices, action: \.deviceDetail))
                ) {
                    DeviceDetailViewiOS(store: $0)
                        .modifier(ContentStyle())
                }

                if horizontalSizeClass == .compact {
                    Button {
                        store.send(.turnOffAllDevices, animation: .default)
                    } label: {
                        LoadingView(store.isLoading == .closingAll) {
                            Image(systemName: "moon.fill")
                            Text(Strings.turnOff.key, bundle: .module)
                        }
                    }
                    .modifier(ContentStyle())

                    Button {
                        store.send(.fetchFromRemote, animation: .default)
                    } label: {
                        LoadingView(store.isLoading == .loadingDevices) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                            Text(Strings.refreshList.key, bundle: .module)
                        }
                    }
                    .modifier(ContentStyle())
                }

            }
            .disabled(store.isLoading.isInFlight).padding()
        }
        .onAppear {
            if case .neverLoaded = store.isLoading {
                store.send(.fetchFromRemote)
            }
        }
        .navigationBarTitle(Text(Strings.kasaName.key, bundle: .module))
    }

}

public struct DeviceRelayFailedViewiOS: View {
    let store: StoreOf<DeviceReducer>

    public var body: some View {
        VStack {
            StateImageView(
                details: store.details,
                isActive: store.isLoading
            )
            Text(store.name).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding()
    }
}

public struct DeviceDetailViewiOS: View {

    init(store: StoreOf<DeviceReducer>) {
        self.store = store
    }

    @Bindable private var store: StoreOf<DeviceReducer>
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

    public var body: some View {
        VStack {
            switch store.details {
            case .status:
                DeviceNoChildViewiOS(store: self.store)
            case .noRelay:
                DeviceChildGroupViewiOS(store: self.store)
            case .failed:
                DeviceRelayFailedViewiOS(store: self.store)
            }
            if store.details.info != nil {
                let button = Button {
                    store.send(.presentInfo, animation: .default)
                } label: {
                    Image(systemName: "info.bubble.fill")
                        .frame(maxWidth: .infinity)
                        .padding([.bottom])
                }
                if horizontalSizeClass == .compact {
                    button.navigationDestination(
                        item: $store.scope(state: \.destination?.info, action: \.destination.info)
                    ) { store in
                        DeviceInfoViewiOS(store: store)
                    }

                } else {
                    button.sheet(
                        item: $store.scope(state: \.destination?.info, action: \.destination.info)
                    ) { store in
                        DeviceInfoViewiOS(store: store)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .disabled(store.isLoading)
    }
}

public struct DeviceInfoViewiOS: View {

    let store: StoreOf<DeviceInfoReducer>
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

    public var body: some View {
        NavigationStack {
            List {
                let info = store.info
                DeviceInfoEntryiOS(settingName: .model, value: info.model.rawValue, imageName: "poweroutlet.type.b")
                DeviceInfoEntryiOS(
                    settingName: .hardwareVersion,
                    value: info.hardwareVersion.rawValue,
                    imageName: "hammer"
                )
                DeviceInfoEntryiOS(
                    settingName: .softwareVersion,
                    value: info.softwareVersion.rawValue,
                    imageName: "gear.badge"
                )
                DeviceInfoEntryiOS(
                    settingName: .macAddress,
                    value: info.macAddress.rawValue,
                    imageName: "network"
                )
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(store.deviceName).font(.headline)
                }
                if horizontalSizeClass != .compact {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            store.send(.dismiss)
                        } label: {
                            Text(Strings.doneAction.key, bundle: .module)
                        }
                    }
                }
            }
        }
    }

}

public struct DeviceInfoEntryiOS: View {
    let settingName: Strings
    let value: String
    let imageName: String
    public var body: some View {
        HStack {
            Image(systemName: imageName)
            Text(settingName.key, bundle: .module)
            Spacer()
            Text(value).foregroundColor(.gray).textSelection(.enabled)
        }
    }
}

public struct DeviceNoChildViewiOS: View {

    @Bindable private var store: StoreOf<DeviceReducer>

    init(store: StoreOf<DeviceReducer>) {
        self.store = store
    }

    public var body: some View {
        Button {
            store.send(.toggle, animation: .default)
        } label: {
            VStack {
                StateImageView(
                    details: store.details,
                    isActive: store.isLoading
                )

                Text(store.name).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
    }
}

public struct DeviceChildGroupViewiOS: View {

    let store: StoreOf<DeviceReducer>

    public var body: some View {

        VStack(alignment: .center) {
            HStack {
                Image(systemName: "rectangle.3.group.fill")
                Text(Strings.deviceGroup.key, bundle: .module)
            }
            .frame(maxWidth: .infinity).padding()
            ForEach(
                store.scope(state: \.children, action: \.deviceChild)
            ) { store in
                DeviceChildViewiOS(store: store)
            }
        }
        .padding([.bottom])
    }
}

public struct DeviceChildViewiOS: View {

    init(store: StoreOf<DeviceChildReducer>) {
        self.store = store
    }

    @Bindable private var store: StoreOf<DeviceChildReducer>

    public var body: some View {
        VStack {
            Button {
                store.send(.toggleChild, animation: .default)
            } label: {
                HStack {
                    StateImageView(
                        relay: store.relay,
                        isActive: store.isLoading
                    )
                    Text(store.name)
                }
                .frame(maxWidth: .infinity)
                .padding([.leading, .trailing])
            }
        }
        .disabled(store.isLoading)
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}

struct ContentStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(minHeight: 100)
            .background(Color.tile.opacity(0.20))
            .clipShape(.rect(cornerRadius: 32))
    }
}

#if DEBUG

#Preview("Empty") {
    DeviceListViewiOS(
        store: Store(
            initialState: .emptyNeverLoaded,
            reducer: { DevicesReducer() }
        )
    )
    .previewDisplayName("empty")
}

#Preview("Link") {
    DeviceListViewiOS(
        store: Store(
            initialState: .emptyWithLink,
            reducer: { DevicesReducer() }
        )
    )
}

#Preview("Routes") {
    DeviceListViewiOS(
        store: Store(
            initialState: .multiRoutes(
                parentError: "Error parent",
                childError: "Error child"
            ),
            reducer: { DevicesReducer() }
        )
    )
}

#Preview("5 item") {
    DeviceListViewiOS(
        store: Store(
            initialState: .nDeviceLoaded(n: 5, indexFailed: [1, 4]),
            reducer: { DevicesReducer() }
        )
    )
}

#Preview("Group") {
    DeviceListViewiOS(
        store: Store(
            initialState: .nDeviceLoaded(n: 5, childrenCount: 4, indexFailed: [3]),
            reducer: { DevicesReducer()._printChanges() }
        )
    )
}

#Preview("Error on item") {
    DeviceListViewiOS(
        store: Store(
            initialState: .nDeviceLoaded(n: 4),
            reducer: {
                DevicesReducer()
                    .dependency(\.devicesClient, .devicesEnvErrorWithDefaults())
            }
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("Device Info") {
    DeviceListViewiOS(
        store: Store(
            initialState: .deviceWithInfo(),
            reducer: { DevicesReducer() }
        )
    )
}
#endif
#endif
