import ComposableArchitecture
import Combine
import Tagged
import KasaCore
import Foundation


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
    static func mock(waitFor seconds: UInt64 = 2) -> Self {
        Self(
            toggle: { (_,_, _) in
                try await taskSleep(for: seconds)
                return true
            }
        )
    }
}
#endif

