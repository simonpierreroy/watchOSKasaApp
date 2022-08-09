
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
        loadDevices: @escaping @Sendable () async throws -> [Device],
        loadUser: @escaping @Sendable () async -> User?
    ) {
        self.loadDevices = loadDevices
        self.loadUser = loadUser
        
    }
    public let loadDevices:  @Sendable () async throws -> [Device]
    public let loadUser: @Sendable () async -> User?
}


#if DEBUG
public extension WidgetEnvironment {
    static let mock = Self(
        loadDevices: DevicesEnvironment.mock.cache.load,
        loadUser:  UserEnvironment.mock.cache.load
    )
}
#endif
