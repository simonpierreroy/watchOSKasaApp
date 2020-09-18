import ComposableArchitecture
import Combine
import Tagged
import KasaCore


public struct DeviceDetailEvironment {
    public typealias ToggleEffect = (Token, Device.ID) -> AnyPublisher<RelayIsOn, Error>
    public let toggle: ToggleEffect
    public let mainQueue: AnySchedulerOf<DispatchQueue>
}

extension DeviceDetailEvironment {
    public init(devicesEnv: DevicesEnvironment) {
        self.toggle = devicesEnv.toggleDevicesState
        self.mainQueue = devicesEnv.mainQueue
    }
}


#if DEBUG
extension DeviceDetailEvironment {
    static let mockDetailEnv = DeviceDetailEvironment (
        toggle: { (_,_) in
            Just(RelayIsOn.init(rawValue: true))
                .mapError(absurd)
                .delay(for: 2, scheduler: DispatchQueue.main)
                .eraseToAnyPublisher() },
        mainQueue: DispatchQueue.main.eraseToAnyScheduler()
    )
}
#endif

