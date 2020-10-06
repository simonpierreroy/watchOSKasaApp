import Foundation
import ComposableArchitecture
import Combine
import Tagged
import KasaCore

public struct Device: Equatable, Identifiable, Codable {
    public init(id: Id, name: String) {
        self.id = id
        self.name = name
    }
    public typealias Id = Tagged<Device, String>
    
    public let id: Id
    public let name: String
    
    public func deepLink() -> Link {
        return Link.device(self.id)
    }
}

public enum Link: Equatable {
    case device(Device.ID)
    case invalid
    case error
    
    public static let errorURL = URL(string: "link/error")!
    public static let baseURL = URL(string: "link/device/")!
    public static let invalidURL = Link.baseURL.appendingPathComponent("invalid")
    
    public func getURL() -> URL {
        switch self {
        case .device(let id):
            return Link.baseURL.appendingPathComponent("\(id.rawValue)")
        case .invalid:
            return Link.invalidURL
        case .error:
            return Link.errorURL
        }
    }
}

public struct DevicesEnvironment {
    
    public init(
        mainQueue: AnySchedulerOf<DispatchQueue>,
        backgroundQueue: AnySchedulerOf<DispatchQueue>,
        loadDevices: @escaping (Token) -> AnyPublisher<[Device], Error>,
        toggleDevicesState: @escaping DeviceDetailEvironment.ToggleEffect,
        getDevicesState: @escaping (Token, Device.ID) -> AnyPublisher<RelayIsOn, Error>,
        changeDevicesState: @escaping (Token, Device.ID, RelayIsOn) -> AnyPublisher<RelayIsOn, Error>,
        devicesCache: DevicesCache
    ) {
        self.mainQueue = mainQueue
        self.backgroundQueue = backgroundQueue
        self.loadDevices = loadDevices
        self.toggleDevicesState = toggleDevicesState
        self.getDevicesState = getDevicesState
        self.changeDevicesState = changeDevicesState
        self.devicesCache = devicesCache
    }
    
    public let mainQueue: AnySchedulerOf<DispatchQueue>
    public let backgroundQueue: AnySchedulerOf<DispatchQueue>
    public let loadDevices: (Token) -> AnyPublisher<[Device], Error>
    public let toggleDevicesState: DeviceDetailEvironment.ToggleEffect
    public let getDevicesState: (Token, Device.ID) -> AnyPublisher<RelayIsOn, Error>
    public let changeDevicesState: (Token, Device.ID, RelayIsOn) -> AnyPublisher<RelayIsOn, Error>
    public let devicesCache: DevicesCache
}

public struct DevicesCache {
    public init(
        save: @escaping ([Device]) ->  AnyPublisher<Void, Error>,
        load: AnyPublisher<[Device], Error>
    ) {
        self.save = save
        self.load = load
    }
    
    public let save: ([Device]) ->  AnyPublisher<Void, Error>
    public let load: AnyPublisher<[Device], Error>
}

#if DEBUG
public extension DevicesEnvironment {
    
    static let debugDevice1 = Device.init(id: "1", name: "Test device 1")
    static let debugDevice2 = Device.init(id: "2", name: "Test device 2")

    static let mockDevicesEnv = DevicesEnvironment (
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        backgroundQueue: DispatchQueue.main.eraseToAnyScheduler(),
        loadDevices: { token in
            return Effect.future{ (work) in
                work(.success([
                    DevicesEnvironment.debugDevice1,
                    DevicesEnvironment.debugDevice2
                ]))
            }.delay(for: 2, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
        }, toggleDevicesState: { (_,_) in
            Just(RelayIsOn.init(rawValue: true))
                .mapError(absurd)
                .delay(for: 2, scheduler: DispatchQueue.main)
                .eraseToAnyPublisher() },
        getDevicesState: { (_,_) in
            Just(RelayIsOn.init(rawValue: true))
                .mapError(absurd)
                .delay(for: 2, scheduler: DispatchQueue.main)
                .eraseToAnyPublisher() },
        changeDevicesState: { (_,_, state) in
            Just(state.toggle())
                .mapError(absurd)
                .delay(for: 2, scheduler: DispatchQueue.main)
                .eraseToAnyPublisher() },
        devicesCache:  DevicesCache(
            save: { _ in Empty(completeImmediately: true).eraseToAnyPublisher() } ,
            load: Just([
                DevicesEnvironment.debugDevice1,
                DevicesEnvironment.debugDevice2
            ]).mapError(absurd)
            .eraseToAnyPublisher()
        )
    )
}

public extension DevicesEnvironment {
    static func devicesEnvError(loadError: String, toggleError: String, getDevicesError: String, changeDevicesError: String) -> DevicesEnvironment {
        return DevicesEnvironment.init(
            mainQueue: mockDevicesEnv.mainQueue,
            backgroundQueue: mockDevicesEnv.backgroundQueue,
            loadDevices:{ _ in
                return Just([])
                    .tryMap{ _ in throw NSError(domain: loadError, code: 1, userInfo: nil) }
                    .eraseToAnyPublisher()
            },
            toggleDevicesState: { _, _ in
                return Just(RelayIsOn.init(rawValue: true))
                    .tryMap{ _ in throw NSError(domain: toggleError, code: 2, userInfo: nil) }
                    .eraseToAnyPublisher()
            },
            getDevicesState:{ token, id in
                return Just(RelayIsOn.init(rawValue: true))
                    .tryMap{ _ in throw NSError(domain: getDevicesError, code: 3, userInfo: nil) }
                    .eraseToAnyPublisher()
            },
            changeDevicesState: { token, id, state in
                return  Just(RelayIsOn.init(rawValue: true))
                    .tryMap{ _ in throw NSError(domain: changeDevicesError, code: 4, userInfo: nil) }
                    .eraseToAnyPublisher()
            }, devicesCache: mockDevicesEnv.devicesCache
        )
    }
}
#endif


