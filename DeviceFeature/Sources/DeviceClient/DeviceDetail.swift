import ComposableArchitecture
import Combine
import Tagged
import KasaCore


public struct DeviceDetailEvironment {
    public typealias ToggleEffect = @Sendable (Token, Device.ID, Device.ID?) async throws -> RelayIsOn
    public let toggle: ToggleEffect
}

extension DeviceDetailEvironment {
    public init(devicesEnv: DevicesEnvironment) {
        self.toggle = devicesEnv.repo.toggleDeviceRelayState
    }
}


#if DEBUG
extension DeviceDetailEvironment {
    static let mock = Self(
        toggle: { (_,_, _) in
            try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
            return true
        }
    )
}

public extension Link.URLParser {
    static let mockDeviceIdOne = Self { url in
        return .device(.init(rawValue: "1"))
    }
}
#endif

