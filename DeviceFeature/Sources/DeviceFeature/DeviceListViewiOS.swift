//
//  SwiftUIView.swift
//  
//
//  Created by Simon-Pierre Roy on 10/1/20.
//

import SwiftUI
import Combine
import ComposableArchitecture
import DeviceClient
import BaseUI

#if os(iOS)

public struct DeviceListViewiOS: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    private let store: Store<StateView, Action>
    public init(store: Store<StateView, Action>) {
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
                                        viewStore.send(.tappedLogout)
                                    } label: {
                                        Text(Strings.logout_app.key, bundle: .module)
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
            }.alert(
                item: viewStore.binding(
                    get: { $0.errorMessageToDisplayText.map(DeviceListViewiOS.AlertInfo.init(title:))},
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
    init(store: Store<DeviceListViewiOS.StateView, DeviceListViewiOS.Action>) {
        self.store = store
    }
    
    private func imageColor(_ loading: Bool) -> Color {
        loading ? Color.gray :Color.logout
    }
    
    public var body: some View {
        WithViewStore(self.store) { viewStore in
            List(ListSideBar.allCases) { tab in
                switch tab {
                case .refresh:
                    Button(action: { viewStore.send(.tappedRefreshButton)}) {
                        LoadingView(.constant(viewStore.isRefreshingDevices == .loadingDevices)){
                            HStack {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .foregroundColor(imageColor(viewStore.isRefreshingDevices.isInFlight))
                                Text(Strings.refresh_list.key, bundle: .module)
                            }
                        }
                    }
                case .logout:
                    Button {
                        viewStore.send(.tappedLogout)
                    } label: {
                        HStack {
                            Image(systemName: "book.closed.fill")
                                .foregroundColor(imageColor(viewStore.isRefreshingDevices.isInFlight))
                            Text(Strings.logout_app.key, bundle: .module)
                        }
                    }
                case .closeAll:
                    Button(action: { viewStore.send(.tappedCloseAll)}) {
                        LoadingView(.constant(viewStore.isRefreshingDevices == .closingAll)) {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .foregroundColor(imageColor(viewStore.isRefreshingDevices.isInFlight))
                                Text(Strings.close_all.key, bundle: .module)
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
    
    public init(store: Store<DeviceListViewiOS.StateView, DeviceListViewiOS.Action>) {
        self.store = store
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
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
                        Button(action: { viewStore.send(.tappedCloseAll)}) {
                            LoadingView(.constant(viewStore.isRefreshingDevices == .closingAll)) {
                                Image(systemName: "moon.fill")
                                Text(Strings.close_all.key, bundle: .module)
                            }
                        }
                        .modifier(ContentStyle(isLoading: viewStore.isRefreshingDevices.isInFlight))
                        
                        Button(action: { viewStore.send(.tappedRefreshButton)}) {
                            LoadingView(.constant(viewStore.isRefreshingDevices == .loadingDevices)){ Image(systemName: "arrow.clockwise.circle.fill")
                                Text(Strings.refresh_list.key, bundle: .module)
                            }
                        }
                        .modifier(ContentStyle(isLoading: viewStore.isRefreshingDevices.isInFlight))
                    }
                    
                }.disabled(viewStore.isRefreshingDevices.isInFlight).padding()
            }.onAppear{
                if case .nerverLoaded = viewStore.isRefreshingDevices {
                    viewStore.send(.viewAppearReload)
                }
            }
        }.navigationBarTitle("Kasa")
    }
}

public extension DeviceListViewiOS {
    
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
            case tappedDeviceChild(index: DeviceSate.ID, action: DeviceChildAction)
        }
        
        case tappedCloseAll
        case tappedErrorAlert
        case tappedLogout
        case viewAppearReload
        case tappedRefreshButton
        case tappedDevice(index: DeviceSate.ID, action: DeviceAction)
    }
}

extension DeviceListViewiOS {
    struct AlertInfo: Identifiable {
        var title: String
        var id: String { self.title }
        
    }
}

public struct DeviceDetailViewiOS: View {
    
    let store: Store<DeviceSate, DeviceListViewiOS.Action.DeviceAction>
    
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
                            Text(Strings.device_group.key, bundle: .module)
                        }
                        Spacer()
                        ForEachStore(
                            self.store.scope(
                                state: \DeviceSate.children,
                                action: DeviceListViewiOS.Action.DeviceAction.tappedDeviceChild(index:action:)
                            ) , content: { store in
                                DeviceChildViewiOS(store: store)
                            })
                    }.padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .disabled(viewStore.isLoading)
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

public struct DeviceNoChildViewiOS: View {
    
    let store: Store<DeviceSate, DeviceListViewiOS.Action.DeviceAction>
    
    public var body: some View {
        WithViewStore(self.store) { viewStore in
            Button(action: { viewStore.send(.tapped) }) {
                LoadingView(.constant(viewStore.isLoading)){
                    VStack {
                        switch viewStore.relay?.rawValue {
                        case .some(true):
                            Image(systemName: "lightbulb.fill").font(.title3).tint(Color.yellow)
                            Text(viewStore.name).multilineTextAlignment(.center)
                        case .some(false):
                            Image(systemName: "lightbulb.slash.fill").font(.title3).tint(Color.blue)
                            Text(viewStore.name).multilineTextAlignment(.center)
                        case .none:
                            EmptyView()
                        }
                    }.padding()
                }
            }
        }
    }
}

public struct DeviceChildViewiOS: View {
    
    let store: Store<DeviceSate.DeviceChildrenSate, DeviceChildAction>
    
    public var body: some View {
        WithViewStore(self.store) { viewStore in
            Button(action: { viewStore.send(.toggleChild) }) {
                HStack {
                    Image(
                        systemName:
                            viewStore.relay == true ? "lightbulb.fill" :  "lightbulb.slash.fill"
                    ).font(.title3)
                        .tint(viewStore.relay == true ? Color.yellow :  Color.blue)
                    Text("\(viewStore.name)")
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

public extension DeviceDetailAction {
    init(viewDetailAction: DeviceListViewiOS.Action.DeviceAction) {
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

#if DEBUG
extension DeviceListViewiOS.StateView {
    init(devices: DevicesState) {
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

extension DevicesAtion {
    init(deviceAction: DeviceListViewiOS.Action) {
        switch deviceAction {
        case .tappedDevice(index: let idx, action: let action):
            let deviceDetailAction = DeviceDetailAction.init(viewDetailAction: action)
            self = .deviceDetail(index: idx, action: deviceDetailAction)
        case .tappedErrorAlert:
            self = .errorHandled
        case .tappedRefreshButton, .viewAppearReload:
            self = .fetchFromRemote
        case .tappedCloseAll:
            self = .closeAll
        case .tappedLogout:
            self = .empty
        }
    }
}


struct DeviceListViewiOS_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DeviceListViewiOS(
                store: Store<DevicesState, DevicesAtion>.init(
                    initialState: .emptyNeverLoaded,
                    reducer: devicesReducer,
                    environment: .mock
                ).scope(
                    state: DeviceListViewiOS.StateView.init(devices:),
                    action: DevicesAtion.init(deviceAction:)
                )
            ).previewDisplayName("empty")
            
            DeviceListViewiOS(
                store: Store<DevicesState, DevicesAtion>.init(
                    initialState: .emptyLoggedLink,
                    reducer: devicesReducer,
                    environment: .mock
                ).scope(
                    state: DeviceListViewiOS.StateView.init(devices:),
                    action: DevicesAtion.init(deviceAction:)
                )
            ).previewDisplayName("Link")
            
            DeviceListViewiOS(
                store: Store<DevicesState, DevicesAtion>.init(
                    initialState: .nDeviceLoaded(n: 5),
                    reducer: devicesReducer,
                    environment: .mock
                ).scope(
                    state: DeviceListViewiOS.StateView.init(devices:),
                    action: DevicesAtion.init(deviceAction:)
                )
            ).previewDisplayName("5 item")
            
            DeviceListViewiOS(
                store: Store<DevicesState, DevicesAtion>.init(
                    initialState: .nDeviceLoaded(n: 5, childrenCount: 4),
                    reducer: devicesReducer,
                    environment: .mock
                ).scope(
                    state: DeviceListViewiOS.StateView.init(devices:),
                    action: DevicesAtion.init(deviceAction:)
                )
            ).previewDisplayName("Group")
             
            DeviceListViewiOS(
                store: Store<DevicesState, DevicesAtion>.init(
                    initialState: .nDeviceLoaded(n: 4),
                    reducer: devicesReducer,
                    environment: .devicesEnvError(
                        loadError: "Load",
                        toggleError: "Toggle",
                        getDevicesError: "Get",
                        changeDevicesError: "Change"
                    )
                ).scope(
                    state: DeviceListViewiOS.StateView.init(devices:),
                    action: DevicesAtion.init(deviceAction:)
                )
            ).preferredColorScheme(.dark)
                .previewDisplayName("Error on item")
        }
    }
}
#endif
#endif

