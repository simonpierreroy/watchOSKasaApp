//
//  SwiftUIView.swift
//
//
//  Created by Simon-Pierre Roy on 10/1/20.
//

import BaseUI
import Combine
import ComposableArchitecture
import DeviceClient
import Foundation
import KasaCore
import SwiftUI

#if os(iOS)

public struct DeviceListViewiOS: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

    private let store: StoreOf<DevicesReducer>
    public init(
        store: StoreOf<DevicesReducer>
    ) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(self.store, observe: always, removeDuplicates: { _, _ in true }) { viewStore in
            Group {
                if horizontalSizeClass == .compact {
                    NavigationStack {
                        DeviceListViewBase(store: store)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button {
                                        viewStore.send(.delegate(.logout), animation: .default)
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
            .alert(
                store: self.store.scope(
                    state: \.$alert,
                    action: \.alert
                )
            )

        }
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
        WithViewStore(self.store, observe: \.isLoading) { viewStore in
            List(ListSideBar.allCases) { tab in
                switch tab {
                case .refresh:
                    Button {
                        viewStore.send(.fetchFromRemote, animation: .default)
                    } label: {
                        LoadingView(.constant(viewStore.state == .loadingDevices)) {
                            HStack {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .foregroundColor(imageColor(viewStore.state.isInFlight))
                                Text(Strings.refreshList.key, bundle: .module)
                            }
                        }
                    }
                case .logout:
                    Button {
                        viewStore.send(.delegate(.logout), animation: .default)
                    } label: {
                        HStack {
                            Image(systemName: "book.closed.fill")
                                .foregroundColor(imageColor(viewStore.state.isInFlight))
                            Text(Strings.logoutApp.key, bundle: .module)
                        }
                    }
                case .turnOffAll:
                    Button {
                        viewStore.send(.turnOffAllDevices, animation: .default)
                    } label: {
                        LoadingView(.constant(viewStore.state == .closingAll)) {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .foregroundColor(imageColor(viewStore.state.isInFlight))
                                Text(Strings.turnOff.key, bundle: .module)
                            }
                        }
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .disabled(viewStore.state.isInFlight)
            .navigationTitle(Text(Strings.kasaName.key, bundle: .module))
        }
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
        WithViewStore(self.store, observe: \.isLoading) { viewStore in
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEachStore(
                        self.store.scope(
                            state: \.devices,
                            action: \.deviceDetail
                        ),
                        content: {
                            DeviceDetailViewiOS(store: $0)
                                .modifier(
                                    ContentStyle(isLoading: viewStore.state.isInFlight)
                                )

                        }
                    )

                    if horizontalSizeClass == .compact {
                        Button {
                            viewStore.send(.turnOffAllDevices, animation: .default)
                        } label: {
                            LoadingView(.constant(viewStore.state == .closingAll)) {
                                Image(systemName: "moon.fill")
                                Text(Strings.turnOff.key, bundle: .module)
                            }
                        }
                        .modifier(ContentStyle(isLoading: viewStore.state.isInFlight))

                        Button {
                            viewStore.send(.fetchFromRemote, animation: .default)
                        } label: {
                            LoadingView(.constant(viewStore.state == .loadingDevices)) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                Text(Strings.refreshList.key, bundle: .module)
                            }
                        }
                        .modifier(ContentStyle(isLoading: viewStore.state.isInFlight))
                    }

                }
                .disabled(viewStore.state.isInFlight).padding()
            }
            .onAppear {
                if case .neverLoaded = viewStore.state {
                    viewStore.send(.fetchFromRemote)
                }
            }
        }
        .navigationBarTitle(Text(Strings.kasaName.key, bundle: .module))
    }
}

public struct DeviceRelayFailedViewiOS: View {
    let store: StoreOf<DeviceReducer>

    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack {
                StateImageView(
                    details: viewStore.details,
                    isActive: viewStore.isLoading
                )
                Text(viewStore.name).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding()
        }
    }
}

public struct DeviceDetailViewiOS: View {

    let store: StoreOf<DeviceReducer>
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack {
                switch viewStore.details {
                case .status:
                    DeviceNoChildViewiOS(store: self.store)
                case .noRelay:
                    DeviceChildGroupViewiOS(store: self.store)
                case .failed:
                    DeviceRelayFailedViewiOS(store: self.store)
                }
                if viewStore.details.info != nil {
                    let button = Button {
                        viewStore.send(.presentInfo, animation: .default)
                    } label: {
                        Image(systemName: "info.bubble.fill")
                            .frame(maxWidth: .infinity)
                            .padding([.bottom])
                    }
                    if horizontalSizeClass == .compact {
                        button.navigationDestination(
                            store: self.store.scope(state: \.$destination.info, action: \.destination.info)
                        ) { store in
                            DeviceInfoViewiOS(store: store)
                        }

                    } else {
                        button.sheet(
                            store: self.store.scope(state: \.$destination.info, action: \.destination.info)
                        ) { store in
                            DeviceInfoViewiOS(store: store)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .disabled(viewStore.isLoading)
        }
    }
}

public struct DeviceInfoViewiOS: View {

    let store: StoreOf<DeviceInfoReducer>
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationStack {
                List {
                    let info = viewStore.info
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
                        Text(viewStore.deviceName).font(.headline)
                    }
                    if horizontalSizeClass != .compact {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                viewStore.send(.dismiss)
                            } label: {
                                Text(Strings.doneAction.key, bundle: .module)
                            }
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

    let store: StoreOf<DeviceReducer>

    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Button {
                viewStore.send(.toggle, animation: .default)
            } label: {
                VStack {
                    StateImageView(
                        details: viewStore.details,
                        isActive: viewStore.isLoading
                    )

                    Text(viewStore.name).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
            .alert(
                store: self.store.scope(state: \.$destination.alert, action: \.destination.alert)
            )
        }
    }
}

public struct DeviceChildGroupViewiOS: View {

    let store: StoreOf<DeviceReducer>

    public var body: some View {
        WithViewStore(self.store, observe: { $0.isLoading }) { viewStore in

            VStack(alignment: .center) {
                HStack {
                    Image(systemName: "rectangle.3.group.fill")
                    Text(Strings.deviceGroup.key, bundle: .module)
                }
                .frame(maxWidth: .infinity).padding()
                ForEachStore(
                    self.store.scope(
                        state: \.children,
                        action: \.deviceChild
                    ),
                    content: { store in
                        DeviceChildViewiOS(store: store)
                    }
                )
            }
            .padding([.bottom])
        }
    }
}

public struct DeviceChildViewiOS: View {

    let store: StoreOf<DeviceChildReducer>

    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack {
                Button {
                    viewStore.send(.toggleChild, animation: .default)
                } label: {
                    HStack {
                        StateImageView(
                            relay: viewStore.relay,
                            isActive: viewStore.isLoading
                        )
                        Text(viewStore.name)
                    }
                    .frame(maxWidth: .infinity)
                    .padding([.leading, .trailing])
                }
            }
            .disabled(viewStore.isLoading)
            .alert(
                store: self.store.scope(
                    state: \.$alert,
                    action: \.alert
                )
            )
        }
    }
}

struct ContentStyle: ViewModifier {
    let isLoading: Bool
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
            initialState: .emptyLoggedLink,
            reducer: { DevicesReducer() }
        )
    )
}

#Preview("Routes") {
    DeviceListViewiOS(
        store: Store(
            initialState: .multiRoutes(
                parentError: "Erorr parent",
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
            reducer: { DevicesReducer() }
        )
    )
}

#Preview("Error on item") {
    DeviceListViewiOS(
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
                    ._printChanges()
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
