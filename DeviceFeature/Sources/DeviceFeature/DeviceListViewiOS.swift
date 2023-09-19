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

    private let store: Store<StateView, Action>
    public init(
        store: Store<StateView, Action>
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
                                        viewStore.send(.tappedLogout, animation: .default)
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
                    action: { .alert($0) }
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

    private let store: Store<DeviceListViewiOS.StateView, DeviceListViewiOS.Action>
    init(
        store: Store<DeviceListViewiOS.StateView, DeviceListViewiOS.Action>
    ) {
        self.store = store
    }

    private func imageColor(_ loading: Bool) -> Color {
        loading ? Color.gray : Color.logout
    }

    public var body: some View {
        WithViewStore(self.store, observe: \.isRefreshingDevices) { viewStore in
            List(ListSideBar.allCases) { tab in
                switch tab {
                case .refresh:
                    Button {
                        viewStore.send(.tappedRefreshButton, animation: .default)
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
                        viewStore.send(.tappedLogout, animation: .default)
                    } label: {
                        HStack {
                            Image(systemName: "book.closed.fill")
                                .foregroundColor(imageColor(viewStore.state.isInFlight))
                            Text(Strings.logoutApp.key, bundle: .module)
                        }
                    }
                case .turnOffAll:
                    Button {
                        viewStore.send(.tappedTurnOffAll, animation: .default)
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

    private let store: Store<DeviceListViewiOS.StateView, DeviceListViewiOS.Action>

    public init(
        store: Store<DeviceListViewiOS.StateView, DeviceListViewiOS.Action>
    ) {
        self.store = store
    }

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    public var body: some View {
        WithViewStore(self.store, observe: \.isRefreshingDevices) { viewStore in
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEachStore(
                        self.store.scope(
                            state: \.devicesToDisplay,
                            action: DeviceListViewiOS.Action.tappedDevice(index:action:)
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
                            viewStore.send(.tappedTurnOffAll, animation: .default)
                        } label: {
                            LoadingView(.constant(viewStore.state == .closingAll)) {
                                Image(systemName: "moon.fill")
                                Text(Strings.turnOff.key, bundle: .module)
                            }
                        }
                        .modifier(ContentStyle(isLoading: viewStore.state.isInFlight))

                        Button {
                            viewStore.send(.tappedRefreshButton, animation: .default)
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
                    viewStore.send(.viewAppearReload)
                }
            }
        }
        .navigationBarTitle(Text(Strings.kasaName.key, bundle: .module))
    }
}

extension DeviceListViewiOS {

    public struct StateView: Equatable {
        public init(
            alert: AlertState<DevicesReducer.Action.Alert>?,
            isRefreshingDevices: DevicesReducer.State.Loading,
            devicesToDisplay: IdentifiedArrayOf<DeviceReducer.State>
        ) {
            self.alert = alert
            self.isRefreshingDevices = isRefreshingDevices
            self.devicesToDisplay = devicesToDisplay
        }

        @PresentationState var alert: AlertState<DevicesReducer.Action.Alert>?
        let isRefreshingDevices: DevicesReducer.State.Loading
        let devicesToDisplay: IdentifiedArrayOf<DeviceReducer.State>
    }

    public enum Action {

        public enum DeviceAction {
            case destination(PresentationAction<DeviceReducer.Destination.Action>)
            case tapped
            case tappedShowInfo
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

public struct DeviceRelayFailedViewiOS: View {
    let store: Store<DeviceReducer.State, DeviceListViewiOS.Action.DeviceAction>

    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            let style = styleFor(details: viewStore.details)
            VStack {
                Image(systemName: style.image).font(.title3)
                Text(viewStore.name).multilineTextAlignment(.center).foregroundColor(style.tint)
            }
            .frame(maxWidth: .infinity).padding()
        }
    }
}

public struct DeviceDetailViewiOS: View {

    let store: Store<DeviceReducer.State, DeviceListViewiOS.Action.DeviceAction>
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
                        viewStore.send(.tappedShowInfo, animation: .default)
                    } label: {
                        Image(systemName: "info.bubble.fill")
                            .frame(maxWidth: .infinity)
                            .padding([.bottom])
                    }
                    if horizontalSizeClass == .compact {
                        button.navigationDestination(
                            store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                            state: /DeviceReducer.Destination.State.info,
                            action: DeviceReducer.Destination.Action.info
                        ) { store in
                            DeviceInfoViewiOS(store: store)
                        }

                    } else {
                        button.sheet(
                            store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                            state: /DeviceReducer.Destination.State.info,
                            action: DeviceReducer.Destination.Action.info
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

    let store: Store<DeviceInfoReducer.State, DeviceInfoReducer.Action>
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

    let store: Store<DeviceReducer.State, DeviceListViewiOS.Action.DeviceAction>

    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Button {
                viewStore.send(.tapped, animation: .default)
            } label: {
                VStack {
                    let style = styleFor(details: viewStore.details)
                    Image(systemName: style.image).font(.title3).tint(style.tint)
                    Text(viewStore.name).multilineTextAlignment(.center)
                    if viewStore.isLoading { ProgressView() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
            .alert(
                store: self.store.scope(state: \.$destination, action: { .destination($0) }),
                state: /DeviceReducer.Destination.State.alert,
                action: DeviceReducer.Destination.Action.alert
            )
        }
    }
}

public struct DeviceChildGroupViewiOS: View {

    let store: Store<DeviceReducer.State, DeviceListViewiOS.Action.DeviceAction>

    public var body: some View {
        WithViewStore(self.store, observe: { $0.isLoading }) { viewStore in

            VStack(alignment: .center) {
                HStack {
                    Image(systemName: "rectangle.3.group.fill")
                    Text(Strings.deviceGroup.key, bundle: .module)
                }
                .frame(maxWidth: .infinity).padding()
                if viewStore.state { ProgressView() }
                Spacer()
                ForEachStore(
                    self.store.scope(
                        state: \.children,
                        action: DeviceListViewiOS.Action.DeviceAction.tappedDeviceChild(index:action:)
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

    let store: Store<DeviceChildReducer.State, DeviceChildReducer.Action>

    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack {
                Button {
                    viewStore.send(.toggleChild, animation: .default)
                } label: {
                    HStack {
                        let style = styleFor(relay: viewStore.relay)
                        Image(systemName: style.image).font(.title3).tint(style.tint)
                        Text(viewStore.name)
                    }
                    .frame(maxWidth: .infinity)
                    .padding([.leading, .trailing])
                }
                if viewStore.isLoading { ProgressView() }
            }
            .disabled(viewStore.isLoading)
            .alert(
                store: self.store.scope(
                    state: \.$alert,
                    action: { .alert($0) }
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

extension DeviceReducer.Action {
    public init(
        viewDetailAction: DeviceListViewiOS.Action.DeviceAction
    ) {
        switch viewDetailAction {
        case .tapped:
            self = .toggle
        case .tappedShowInfo:
            self = .presentInfo
        case .destination(let destination):
            self = .destination(destination)
        case .tappedDeviceChild(index: let id, let action):
            self = .deviceChild(index: id, action: action)
        }
    }
}

extension DeviceListViewiOS.StateView {
    public init(
        devices: DevicesReducer.State
    ) {
        self.alert = devices.alert
        self.devicesToDisplay = devices.devices
        self.isRefreshingDevices = devices.isLoading
    }
}

extension DevicesReducer.Action {
    public init(
        deviceAction: DeviceListViewiOS.Action
    ) {
        switch deviceAction {
        case .tappedDevice(index: let idx, let action):
            let deviceDetailAction = DeviceReducer.Action.init(viewDetailAction: action)
            self = .deviceDetail(index: idx, action: deviceDetailAction)
        case .alert(let state):
            self = .alert(state)
        case .tappedRefreshButton, .viewAppearReload:
            self = .fetchFromRemote
        case .tappedTurnOffAll:
            self = .turnOffAllDevices
        case .tappedLogout:
            self = .delegate(.logout)
        }
    }
}

#if DEBUG

#Preview("Empty") {
    DeviceListViewiOS(
        store: Store(
            initialState: .emptyNeverLoaded,
            reducer: { DevicesReducer() }
        )
        .scope(
            state: DeviceListViewiOS.StateView.init(devices:),
            action: DevicesReducer.Action.init(deviceAction:)
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
        .scope(
            state: DeviceListViewiOS.StateView.init(devices:),
            action: DevicesReducer.Action.init(deviceAction:)
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
        .scope(
            state: DeviceListViewiOS.StateView.init(devices:),
            action: DevicesReducer.Action.init(deviceAction:)
        )
    )
}

#Preview("5 item") {
    DeviceListViewiOS(
        store: Store(
            initialState: .nDeviceLoaded(n: 5, indexFailed: [1, 4]),
            reducer: { DevicesReducer() }
        )
        .scope(
            state: DeviceListViewiOS.StateView.init(devices:),
            action: DevicesReducer.Action.init(deviceAction:)
        )
    )
}

#Preview("Group") {
    DeviceListViewiOS(
        store: Store(
            initialState: .nDeviceLoaded(n: 5, childrenCount: 4, indexFailed: [3]),
            reducer: { DevicesReducer() }
        )
        .scope(
            state: DeviceListViewiOS.StateView.init(devices:),
            action: DevicesReducer.Action.init(deviceAction:)
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
        .scope(
            state: DeviceListViewiOS.StateView.init(devices:),
            action: DevicesReducer.Action.init(deviceAction:)
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
        .scope(
            state: DeviceListViewiOS.StateView.init(devices:),
            action: DevicesReducer.Action.init(deviceAction:)
        )
    )
}
#endif
#endif
