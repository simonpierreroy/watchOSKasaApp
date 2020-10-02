import Foundation
import ComposableArchitecture
import Combine
import Tagged
import KasaCore

public struct Device: Equatable, Identifiable {
    public init(id: Id, name: String) {
        self.id = id
        self.name = name
    }
    public typealias Id = Tagged<Device, String>
    
    public let id: Id
    public let name: String
}


public struct DevicesEnvironment {
    
    public init(
        mainQueue: AnySchedulerOf<DispatchQueue>,
        backgroundQueue: AnySchedulerOf<DispatchQueue>,
        loadDevices: @escaping (Token) -> AnyPublisher<[Device], Error>,
        toggleDevicesState: @escaping DeviceDetailEvironment.ToggleEffect,
        getDevicesState: @escaping (Token, Device.ID) -> AnyPublisher<RelayIsOn, Error>,
        changeDevicesState: @escaping (Token, Device.ID, RelayIsOn) -> AnyPublisher<RelayIsOn, Error>
    ) {
        self.mainQueue = mainQueue
        self.backgroundQueue = backgroundQueue
        self.loadDevices = loadDevices
        self.toggleDevicesState = toggleDevicesState
        self.getDevicesState = getDevicesState
        self.changeDevicesState = changeDevicesState
    }
    
    public let mainQueue: AnySchedulerOf<DispatchQueue>
    public let backgroundQueue: AnySchedulerOf<DispatchQueue>
    public let loadDevices: (Token) -> AnyPublisher<[Device], Error>
    public let toggleDevicesState: DeviceDetailEvironment.ToggleEffect
    public let getDevicesState: (Token, Device.ID) -> AnyPublisher<RelayIsOn, Error>
    public let changeDevicesState: (Token, Device.ID, RelayIsOn) -> AnyPublisher<RelayIsOn, Error>
}

#if DEBUG
public extension DevicesEnvironment {
    static let mockDevicesEnv = DevicesEnvironment (
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        backgroundQueue: DispatchQueue.main.eraseToAnyScheduler(),
        loadDevices: { token in
            return Effect.future{ (work) in
                work(.success([
                    Device.init(id: "34", name: "Test device 1"),
                    Device.init(id: "45", name: "Test device 2")
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
                .eraseToAnyPublisher() }
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
                    .tryMap{ _ in throw NSError(domain: toggleError, code: 1, userInfo: nil) }
                    .eraseToAnyPublisher()
            },
            getDevicesState:{ token, id in
                return Just(RelayIsOn.init(rawValue: true))
                    .tryMap{ _ in throw NSError(domain: getDevicesError, code: 2, userInfo: nil) }
                    .eraseToAnyPublisher()
            },
            changeDevicesState: { token, id, state in
                return  Just(RelayIsOn.init(rawValue: true))
                    .tryMap{ _ in throw NSError(domain: changeDevicesError, code: 3, userInfo: nil) }
                    .eraseToAnyPublisher()
            }
        )
    }
}
#endif


