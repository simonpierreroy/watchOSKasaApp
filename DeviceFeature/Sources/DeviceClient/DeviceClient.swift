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
        toggleDevicesState: @escaping DeviceDetailEvironment.ToggleEffect
    ) {
        self.mainQueue = mainQueue
        self.backgroundQueue = backgroundQueue
        self.loadDevices = loadDevices
        self.toggleDevicesState = toggleDevicesState
    }
    
    public let mainQueue: AnySchedulerOf<DispatchQueue>
    public let backgroundQueue: AnySchedulerOf<DispatchQueue>
    public let loadDevices: (Token) -> AnyPublisher<[Device], Error>
    public let toggleDevicesState: DeviceDetailEvironment.ToggleEffect
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
            .eraseToAnyPublisher() }
    )
}
#endif


