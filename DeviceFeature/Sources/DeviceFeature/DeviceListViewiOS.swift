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
        WithViewStore(self.store) { viewStore in
            Group {
                if horizontalSizeClass == .compact {
                    NavigationView {
                        DeviceListViewBase(store: store)
                            .navigationBarItems(
                                trailing:
                                    Button {
                                        viewStore.send(.tappedLogout, animation: .default)
                                    } label: {
                                        Text(Strings.logoutApp.key, bundle: .module)
                                            .foregroundColor(Color.logout)
                                    }
                            )
                    }
                } else {
                    NavigationView {
                        DeviceListViewSideBar(store: store)
                        DeviceListViewBase(store: store)
                    }
                }
            }
            .alert(
                item: viewStore.binding(
                    get: { $0.errorMessageToDisplayText.map(DeviceListViewiOS.AlertInfo.init(title:)) },
                    send: .tappedErrorAlert
                ),
                content: { Alert(title: Text($0.title)) }
            )

        }
    }
}

private struct DeviceListViewSideBar: View {

    private enum ListSideBar: CaseIterable, Hashable, Identifiable {
        case refresh
        case closeAll
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
        WithViewStore(self.store) { viewStore in
            List(ListSideBar.allCases) { tab in
                switch tab {
                case .refresh:
                    Button(action: { viewStore.send(.tappedRefreshButton, animation: .default) }) {
                        LoadingView(.constant(viewStore.isRefreshingDevices == .loadingDevices)) {
                            HStack {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .foregroundColor(imageColor(viewStore.isRefreshingDevices.isInFlight))
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
                                .foregroundColor(imageColor(viewStore.isRefreshingDevices.isInFlight))
                            Text(Strings.logoutApp.key, bundle: .module)
                        }
                    }
                case .closeAll:
                    Button(action: { viewStore.send(.tappedCloseAll, animation: .default) }) {
                        LoadingView(.constant(viewStore.isRefreshingDevices == .closingAll)) {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .foregroundColor(imageColor(viewStore.isRefreshingDevices.isInFlight))
                                Text(Strings.closeAll.key, bundle: .module)
                            }
                        }
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .disabled(viewStore.isRefreshingDevices.isInFlight)
            .navigationTitle(Text("Kasa"))
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
        WithViewStore(self.store) { viewStore in
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
                                    ContentStyle(isLoading: viewStore.isRefreshingDevices.isInFlight)
                                )

                        }
                    )

                    if horizontalSizeClass == .compact {
                        Button(action: { viewStore.send(.tappedCloseAll, animation: .default) }) {
                            LoadingView(.constant(viewStore.isRefreshingDevices == .closingAll)) {
                                Image(systemName: "moon.fill")
                                Text(Strings.closeAll.key, bundle: .module)
                            }
                        }
                        .modifier(ContentStyle(isLoading: viewStore.isRefreshingDevices.isInFlight))

                        Button(action: { viewStore.send(.tappedRefreshButton, animation: .default) }) {
                            LoadingView(.constant(viewStore.isRefreshingDevices == .loadingDevices)) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                Text(Strings.refreshList.key, bundle: .module)
                            }
                        }
                        .modifier(ContentStyle(isLoading: viewStore.isRefreshingDevices.isInFlight))
                    }

                }
                .disabled(viewStore.isRefreshingDevices.isInFlight).padding()
            }
            .onAppear {
                if case .nerverLoaded = viewStore.isRefreshingDevices {
                    viewStore.send(.viewAppearReload)
                }
            }
        }
        .navigationBarTitle("Kasa")
    }
}

extension DeviceListViewiOS {

    public struct StateView: Equatable {
        public init(
            errorMessageToDisplayText: String?,
            isRefreshingDevices: DevicesReducer.State.Loading,
            devicesToDisplay: IdentifiedArrayOf<DeviceReducer.State>
        ) {
            self.errorMessageToDisplayText = errorMessageToDisplayText
            self.isRefreshingDevices = isRefreshingDevices
            self.devicesToDisplay = devicesToDisplay
        }

        let errorMessageToDisplayText: String?
        let isRefreshingDevices: DevicesReducer.State.Loading
        let devicesToDisplay: IdentifiedArrayOf<DeviceReducer.State>
    }

    public enum Action {

        public enum DeviceAction {
            case tapped
            case tappedErrorAlert
            case tappedDeviceChild(index: DeviceChildReducer.State.ID, action: DeviceChildReducer.Action)
        }

        case tappedCloseAll
        case tappedErrorAlert
        case tappedLogout
        case viewAppearReload
        case tappedRefreshButton
        case tappedDevice(index: DeviceReducer.State.ID, action: DeviceAction)
    }
}

extension DeviceListViewiOS {
    struct AlertInfo: Identifiable {
        var title: String
        var id: String { self.title }

    }
}

public struct DeviceDetailViewiOS: View {

    let store: Store<DeviceReducer.State, DeviceListViewiOS.Action.DeviceAction>

    public var body: some View {
        WithViewStore(self.store) { viewStore in
            VStack {
                switch viewStore.relay?.rawValue {
                case .some(true), .some(false):
                    DeviceNoChildViewiOS(store: self.store)
                case .none:
                    VStack(alignment: .center) {
                        HStack {
                            Image(systemName: "rectangle.3.group.fill")
                            Text(Strings.deviceGroup.key, bundle: .module)
                        }
                        if viewStore.isLoading { ProgressView() }
                        Spacer()
                        ForEachStore(
                            self.store.scope(
                                state: \DeviceReducer.State.children,
                                action: DeviceListViewiOS.Action.DeviceAction.tappedDeviceChild(index:action:)
                            ),
                            content: { store in
                                DeviceChildViewiOS(store: store)
                            }
                        )
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .disabled(viewStore.isLoading)
            .alert(
                item: viewStore.binding(
                    get: {
                        CasePath(DeviceReducer.State.Route.error)
                            .extract(from: $0.route)
                            .map { AlertInfo(title: $0) }
                    },
                    send: .tappedErrorAlert
                ),
                content: { Alert(title: Text($0.title)) }
            )
        }
    }
}

public struct DeviceNoChildViewiOS: View {

    let store: Store<DeviceReducer.State, DeviceListViewiOS.Action.DeviceAction>

    public var body: some View {
        WithViewStore(self.store) { viewStore in
            Button(action: { viewStore.send(.tapped, animation: .default) }) {
                VStack {
                    let style = styleForRelayState(relay: viewStore.relay)
                    Image(systemName: style.image).font(.title3).tint(style.taint)
                    Text(viewStore.name).multilineTextAlignment(.center)
                    if viewStore.isLoading { ProgressView() }
                }
                .padding()
            }
        }
    }
}

public struct DeviceChildViewiOS: View {

    let store: Store<DeviceChildReducer.State, DeviceChildReducer.Action>

    public var body: some View {
        WithViewStore(self.store) { viewStore in
            Button(action: { viewStore.send(.toggleChild, animation: .default) }) {
                HStack {
                    let style = styleForRelayState(relay: viewStore.relay)
                    Image(systemName: style.image).font(.title3).tint(style.taint)
                    Text(viewStore.name)
                }
            }
        }
    }
}

extension DeviceDetailViewiOS {
    struct AlertInfo: Identifiable {
        var title: String
        var id: String { self.title }
    }
}

struct ContentStyle: ViewModifier {
    let isLoading: Bool
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(minHeight: 100)
            .background(Color.tile.opacity(0.20))
            .cornerRadius(25)
    }
}

extension DeviceReducer.Action {
    public init(
        viewDetailAction: DeviceListViewiOS.Action.DeviceAction
    ) {
        switch viewDetailAction {
        case .tapped:
            self = .toggle
        case .tappedErrorAlert:
            self = .errorHandled
        case .tappedDeviceChild(index: let id, let action):
            self = .deviceChild(index: id, action: action)
        }
    }
}

extension DeviceListViewiOS.StateView {
    public init(
        devices: DevicesReducer.State
    ) {
        switch devices.route {
        case nil:
            self.errorMessageToDisplayText = nil
        case .some(.error(let error)):
            self.errorMessageToDisplayText = error.localizedDescription
        }

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
        case .tappedErrorAlert:
            self = .errorHandled
        case .tappedRefreshButton, .viewAppearReload:
            self = .fetchFromRemote
        case .tappedCloseAll:
            self = .closeAll
        case .tappedLogout:
            self = .logout
        }
    }
}

#if DEBUG
struct DeviceListViewiOS_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DeviceListViewiOS(
                store: Store(
                    initialState: .emptyNeverLoaded,
                    reducer: DevicesReducer()
                )
                .scope(
                    state: DeviceListViewiOS.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            )
            .previewDisplayName("empty")

            DeviceListViewiOS(
                store: Store(
                    initialState: .emptyLoggedLink,
                    reducer: DevicesReducer()
                )
                .scope(
                    state: DeviceListViewiOS.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            )
            .previewDisplayName("Link")

            DeviceListViewiOS(
                store: Store(
                    initialState: .multiRoutes(
                        parentError: "Erorr parent",
                        childError: "Error child"
                    ),
                    reducer: DevicesReducer()
                )
                .scope(
                    state: DeviceListViewiOS.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            )
            .previewDisplayName("Routes")

            DeviceListViewiOS(
                store: Store(
                    initialState: .nDeviceLoaded(n: 5),
                    reducer: DevicesReducer()
                )
                .scope(
                    state: DeviceListViewiOS.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            )
            .previewDisplayName("5 item")

            DeviceListViewiOS(
                store: Store(
                    initialState: .nDeviceLoaded(n: 5, childrenCount: 4),
                    reducer: DevicesReducer()
                )
                .scope(
                    state: DeviceListViewiOS.StateView.init(devices:),
                    action: DevicesReducer.Action.init(deviceAction:)
                )
            )
            .previewDisplayName("Group")

            DeviceListViewiOS(
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
                    state: DeviceListViewiOS.StateView.init(devices:),
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
