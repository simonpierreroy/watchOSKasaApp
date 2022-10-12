
import Foundation
import Combine
import DeviceClient
import UserClient
import KasaCore
import RoutingClient

public struct WidgetState {
    
    public init(user: User?, device: [Device]) {
        self.user = user
        self.device = device
    }
    
    public let user: User?
    public let device: [Device]
    
}

public struct DataDeviceEntry {
    
    public init(
        date: Date,
        userIsLogged: Bool,
        devices: [Device]
    ) {
        self.date = date
        self.userIsLogged = userIsLogged
        self.devices = devices
    }
    
    public let date: Date
    public let userIsLogged: Bool
    public let devices: [Device]
    
}

public extension DataDeviceEntry {
    static func preview(_ n: Int) -> Self {
        guard n > 0 else {
            return DataDeviceEntry.init(date: Date(), userIsLogged: true, devices: [])
        }
        return DataDeviceEntry(
            date: Date(),
            userIsLogged: true,
            devices: (1...n).map{ Device.init(
                id: .init(rawValue: "\($0)"),
                name: "Lampe du salaon \($0)",
                children: $0 == 3 ? [
                    .init(id: .init(rawValue: "child 1\($0)"), name: "child 1 of \($0)", state: false),
                    .init(id: .init(rawValue: "child 2\($0)"), name: "child 1 of \($0)", state: false)
                ] : [],
                state: false)
            }
        )
    }
    
    static let previewLogout = Self(
        date: Date(),
        userIsLogged: false,
        devices: []
    )
}
