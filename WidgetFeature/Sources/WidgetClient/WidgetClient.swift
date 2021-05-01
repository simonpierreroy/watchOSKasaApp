
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
        loadDevices: AnyPublisher<[Device], Error>,
        loadUser: AnyPublisher<User?, Never>
    ) {
        self.loadDevices = loadDevices
        self.loadUser = loadUser
        
    }
    public let loadDevices: AnyPublisher<[Device], Error>
    public let loadUser: AnyPublisher<User?, Never>
}


#if DEBUG
public extension WidgetEnvironment {
    static let mockEnv = Self(
        loadDevices: DevicesEnvironment.mock.cache.load,
        loadUser:  UserEnvironment.mock.cache.load
    )
}
#endif
