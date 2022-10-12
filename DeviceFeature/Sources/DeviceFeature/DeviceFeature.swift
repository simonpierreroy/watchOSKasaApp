//
//  DeviceDetailFeature.swift
//  
//
//  Created by Simon-Pierre Roy on 9/18/20.
//

import Foundation
import ComposableArchitecture
import Combine
import Tagged
import KasaCore
import DeviceClient

public struct DevicesReducer: ReducerProtocol {
    
    public init() { }
    
    public enum Action {
        case set(to: IdentifiedArrayOf<DeviceReducer.State>)
        case fetchFromRemote
        case send(Error)
        case errorHandled
        case deviceDetail(index: DeviceReducer.State.ID, action: DeviceReducer.Action)
        case closeAll
        case doneClosingAll
        case saveDevicesToCache
        case attempDeepLink(Link)
        case logout
    }
    
    public struct State {
        public static let empty = Self(devices: [], isLoading: .nerverLoaded, route: nil, token: nil)
        
        init(devices: [DeviceReducer.State], isLoading: Loading, route: Route?, token: Token?, link: Link? = nil) {
            self._devices = .init(uniqueElements: devices)
            self.isLoading = isLoading
            self.route = route
            self.token = token
            self.linkToComplete = link
        }
        
        public enum Loading {
            case nerverLoaded
            case loadingDevices
            case closingAll
            case loaded
            
            var isInFlight: Bool {
                switch self {
                case .loadingDevices, .closingAll:
                    return true
                case .loaded, .nerverLoaded:
                    return false
                }
            }
        }
        
        private var _devices: IdentifiedArrayOf<DeviceReducer.State>
        public var devices: IdentifiedArrayOf<DeviceReducer.State> {
            get {
                return .init (uniqueElements: _devices.map {
                    var copy = $0
                    copy.token = self.token
                    return copy
                })
            }
            set { self._devices = newValue }
        }
        
        public enum Route {
            case error(Error)
        }
        
        public var token: Token?
        public var isLoading: Loading
        public var route: Route?
        public var linkToComplete: Link?
    }
    
    @Dependency(\.devicesCache.save) var saveToCache
    @Dependency(\.devicesClient.changeDeviceRelayState) var changeDeviceRelayState
    @Dependency(\.devicesClient.loadDevices) var loadDevices
    @Dependency(\.reloadAppExtensions) var reloadAppExtensions
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .attempDeepLink(let link):
                guard state.isLoading == .loaded else {
                    state.linkToComplete = link
                    return .none
                }
                defer { state.linkToComplete = nil }
                
                switch link {
                case .closeAll: return Effect(value: .closeAll)
                case .device(let id):
                    guard state.devices[id: id] != nil else { return .none }
                    return Effect(value: .deviceDetail(index: id, action: .toggle))
                }
            case .set(let devices):
                state.isLoading = .loaded
                state.devices = devices
                return .run { [linkToComplete = state.linkToComplete] send in
                    await send(.saveDevicesToCache)
                    if let link = linkToComplete {
                        await send(.attempDeepLink(link))
                    }
                }
            case .saveDevicesToCache:
                let list =  state.devices.map(Device.init(deviceState:))
                return .fireAndForget{
                    try await saveToCache(list)
                    await reloadAppExtensions()
                }
            case .fetchFromRemote:
                guard let token = state.token else { return .none }
                state.isLoading = .loadingDevices
                return .task {
                    let devices = try await loadDevices(token).map(DeviceReducer.State.init(device:))
                    let states = IdentifiedArrayOf<DeviceReducer.State>(uniqueElements: devices)
                    return .set(to: states)
                } catch: { return .send($0) }.animation()
            case .send(let error):
                state.isLoading = .loaded
                state.route = .error(error)
                return .none
            case .errorHandled:
                state.route = nil
                return .none
            case .closeAll:
                guard let token = state.token, state.isLoading == .loaded else { return .none }
                state.isLoading = .closingAll
                return .task { [devices = state.devices] in
                    return try await withThrowingTaskGroup(of: Void.self) { group in
                        for device in devices {
                            if let _ = device.relay {
                                group.addTask { _ = try await changeDeviceRelayState(token, device.id, nil, false) }
                            }
                            for child in device.children {
                                group.addTask { _ = try await changeDeviceRelayState(token, device.id, child.id, false) }
                            }
                        }
                        try await group.waitForAll()
                        return .doneClosingAll
                    }
                } catch: { return .send($0) }.animation()
            case .doneClosingAll:
                state.isLoading = .loaded
                return Effect(value: Action.fetchFromRemote)
            case .deviceDetail: return .none
            case .logout: return .none // Will be provide by an other feature
            }
        }.forEach(\.devices, action: /Action.deviceDetail(index:action:)) {
            DeviceReducer()
        }
    }
}

extension DeviceReducer.State {
    init(device: Device) {
        self.id  = device.id
        self.name = device.name
        self.relay = device.state
        let tmpChildren = device.children
            .map {
                DeviceChildReducer.State.init(relay: $0.state, id: $0.id, name: $0.name)
            }
        self.children = .init(uniqueElements: tmpChildren)
    }
}

extension Device {
    init(deviceState: DeviceReducer.State) {
        self.init(
            id: deviceState.id,
            name: deviceState.name,
            children: deviceState.children
                .map { Device.DeviceChild.init(id: $0.id, name: $0.name, state: $0.relay) },
            state:  deviceState.relay
        )
    }
}

#if DEBUG
extension DevicesReducer.State {
    static let emptyLogged = Self(devices: [], isLoading: .nerverLoaded, route: nil, token: "logged")
    static let emptyLoggedLink = Self(devices: [], isLoading: .nerverLoaded, route: nil, token: "logged", link: Device.debugDevice1.deepLink())
    static let emptyLoading = Self(devices: [], isLoading: .loadingDevices, route: nil, token: "logged")
    static let emptyNeverLoaded = Self(devices: [], isLoading: .nerverLoaded, route: nil, token: "logged")
    static let oneDeviceLoaded = Self(devices: [.init(device: .debugDevice1)], isLoading: .loaded, route: nil, token: "logged")
    static func nDeviceLoaded(n: Int, childrenCount: Int = 0) -> Self {
        var children: [Device.DeviceChild] = []
        var state: RelayIsOn? = false
        
        if childrenCount >= 1 {
            children = (1...childrenCount).map {  Device.DeviceChild(id: "child \($0)", name:  "child \($0)", state: true) }
            state = nil
        }
        
        return Self(
            devices: (1...n).map{ DeviceReducer.State(
                device: .init(
                    id: "\($0)",
                    name: "Test device number \($0)",
                    children: children,
                    state: state
                )
            )},
            isLoading: .loaded,
            route: nil,
            token: "logged"
        )
    }
}
#endif
