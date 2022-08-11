import Foundation
import ComposableArchitecture
import Combine
import Tagged
import KasaCore

public struct Device: Equatable, Identifiable, Codable {
    
    public struct DeviceChild: Equatable, Identifiable, Codable {
        public init(id: Id, name: String, state: RelayIsOn) {
            self.id = id
            self.name = name
            self.state = state
        }
        
        public let id: Id
        public let name: String
        public var state: RelayIsOn
    }
    
    
    public init(id: Id, name: String, children: [DeviceChild] = [], state: RelayIsOn?) {
        self.id = id
        self.name = name
        self.children = children
        self.state = state
    }
    
    public typealias Id = Tagged<Device, String>
    
    public let id: Id
    public let name: String
    public let children: [DeviceChild]
    public var state: RelayIsOn?
    
    public func deepLink() -> Link {
        return Link.device(self.id)
    }
}

public enum Link: Equatable {
    
    case device(Device.ID)
    case closeAll
    case invalid
    case error
    
    public static let errorURL = URL(string: "link/error")!
    public static let baseURL = URL(string: "link/device/")!
    public static let cloaseAllURL = URL(string: "link/closeAll")!
    public static let invalidURL = Link.baseURL.appendingPathComponent("invalid")
    
    public func getURL() -> URL {
        switch self {
        case .device(let id):
            return Link.baseURL.appendingPathComponent("\(id.rawValue)")
        case .invalid:
            return Link.invalidURL
        case .error:
            return Link.errorURL
        case .closeAll:
            return Link.cloaseAllURL
        }
    }
}

public extension Link {
    struct URLParser {
        public init(parse: @escaping (URL) -> Link) {
            self.parse = parse
        }
        public let parse: (URL) -> Link
    }
}

public struct DevicesEnvironment {
    
    public init(
        repo: DevicesRepo,
        devicesCache: DevicesCache,
        reloadAppExtensions: @escaping @Sendable () async -> Void
    ) {
        self.repo = repo
        self.cache = devicesCache
        self.reloadAppExtensions = reloadAppExtensions
    }
    
    public let repo: DevicesRepo
    public let cache: DevicesCache
    public let reloadAppExtensions: @Sendable () async -> Void
}

public struct DevicesRepo {
    
    public init(
        loadDevices: @escaping @Sendable (Token) async throws -> [Device],
        toggleDeviceRelayState: @escaping DeviceDetailEvironment.ToggleEffect,
        getDeviceRelayState: @escaping @Sendable (Token, Device.ID, Device.ID?) async throws -> RelayIsOn,
        changeDeviceRelayState: @escaping @Sendable (Token, Device.ID, Device.ID?, RelayIsOn) async throws -> RelayIsOn
    ) {
        
        
        self.loadDevices = loadDevices
        self.toggleDeviceRelayState = toggleDeviceRelayState
        self.getDeviceRelayState = getDeviceRelayState
        self.changeDeviceRelayState = changeDeviceRelayState
        
    }
    
    public let loadDevices: @Sendable (Token) async throws -> [Device]
    public let toggleDeviceRelayState: DeviceDetailEvironment.ToggleEffect
    public let getDeviceRelayState: @Sendable (Token, Device.ID, Device.ID?) async throws -> RelayIsOn
    public let changeDeviceRelayState: @Sendable (Token, Device.ID, Device.ID?, RelayIsOn) async throws -> RelayIsOn
}

public struct DevicesCache {
    public enum Failure: Error {
        case dataConversion
    }
    
    public init(
        save: @escaping @Sendable ([Device]) async throws ->  Void,
        load: @escaping @Sendable () async throws -> [Device]
    ) {
        self.save = save
        self.load = load
    }
    
    public let save: @Sendable ([Device]) async throws ->  Void
    public let load: @Sendable () async throws -> [Device]
}

#if DEBUG
public extension DevicesRepo {
    static func mock(waitFor seconds: UInt64 = 2) ->  Self {
        Self(
            loadDevices: { _ in
                try await taskSleep(for: seconds)
                return [DevicesEnvironment.debugDevice1, DevicesEnvironment.debugDevice2]
            }, toggleDeviceRelayState: { (_,_, _) in
                try await taskSleep(for: seconds)
                return true
            },
            getDeviceRelayState: { (_,_,_) in
                try await taskSleep(for: seconds)
                return true
            },
            changeDeviceRelayState: { (_,_,_, state) in
                try await taskSleep(for: seconds)
                return state.toggle()
            }
        )
    }
}

public extension DevicesCache {
    static let mock = Self(
        save: { _ in return } ,
        load: { [DevicesEnvironment.debugDevice1, DevicesEnvironment.debugDevice2] }
    )
}

public extension DevicesEnvironment {
    
    static let debugDevice1 = Device.init(id: "1", name: "Test device 1", state: false)
    static let debugDevice2 = Device.init(id: "2", name: "Test device 2", state: true)
    
    static func mock(waitFor seconds: UInt64 = 2) -> Self {
        Self(repo: .mock(waitFor: seconds),
             devicesCache: .mock,
             reloadAppExtensions: { return }
        )
    }
}

public extension DevicesEnvironment {
    static func devicesEnvError(loadError: String, toggleError: String, getDevicesError: String, changeDevicesError: String) -> Self {
        return Self(
            repo: .init(
                loadDevices: { _ in throw NSError(domain: loadError, code: 1, userInfo: nil) },
                toggleDeviceRelayState: { _, _, _ in throw NSError(domain: toggleError, code: 2, userInfo: nil) },
                getDeviceRelayState:{ _,_,_ in throw NSError(domain: getDevicesError, code: 3, userInfo: nil) },
                changeDeviceRelayState: { _,_,_,_ in throw NSError(domain: changeDevicesError, code: 4, userInfo: nil) }
            ),
            devicesCache: .mock,
            reloadAppExtensions: mock().reloadAppExtensions
        )
    }
}
#endif


