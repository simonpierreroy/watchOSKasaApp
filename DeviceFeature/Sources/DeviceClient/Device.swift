import Foundation
import ComposableArchitecture
import Combine
import Tagged
import KasaCore

public struct Device: Equatable, Identifiable, Codable {
    
    public struct DeviceChild: Equatable, Identifiable, Codable {
        public init(id: Id, name: String, state: RelayIsOn) {
            self.id = id
            self.name = name
            self.state = state
        }
        
        public let id: Id
        public let name: String
        public var state: RelayIsOn
    }
    
    
    public init(id: Id, name: String, children: [DeviceChild] = [], state: RelayIsOn?) {
        self.id = id
        self.name = name
        self.children = children
        self.state = state
    }
    
    public typealias Id = Tagged<Device, String>
    
    public let id: Id
    public let name: String
    public let children: [DeviceChild]
    public var state: RelayIsOn?
    
    public func deepLink() -> Link {
        return Link.device(self.id)
    }
}

public extension Device {
    
    static let debugDevice1 = Self(id: "1", name: "Test device 1", state: false)
    static let debugDevice2 = Self(id: "2", name: "Test device 2", state: true)
    static let debugDevice3 = Self(
        id: "3",
        name: "Test device 3",
        children: [
            .init(id: "Child 1-3", name: "Child 1 of device 3", state: true),
            .init(id: "Child 2-3", name: "Child 2 of device 3", state: false)
        ],
        state: false
    )
}

public enum Link: Equatable {
    case device(Device.ID)
    case closeAll
}
