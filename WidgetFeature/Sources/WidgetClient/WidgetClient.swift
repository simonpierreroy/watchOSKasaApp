
import Foundation
import Combine
import DeviceClient
import UserClient
import KasaCore

public struct WidgetState {
    
    public init(user: User?, device: [Device]) {
        self.user = user
        self.device = device
    }
    
    public let user: User?
    public let device: [Device]
    
}

public struct WidgetEnvironment {
    
    public init (
        loadDevices: @escaping @Sendable () throws -> [Device],
        loadUser: @escaping @Sendable () -> User?
    ) {
        self.loadDevices = loadDevices
        self.loadUser = loadUser
        
    }
    public let loadDevices:  @Sendable () throws -> [Device]
    public let loadUser: @Sendable () -> User?
}


#if DEBUG
public extension WidgetEnvironment {
    static func mock(waitFor seconds: UInt64 = 2) -> Self {
        Self(
            loadDevices: DevicesEnvironment.mock(waitFor: seconds).cache.loadBlocking,
            loadUser:  UserEnvironment.mock(waitFor: seconds).cache.loadBlocking
        )
    }
}
#endif
