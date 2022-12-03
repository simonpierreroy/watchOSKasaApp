import Combine
import ComposableArchitecture
import Foundation
import KasaCore
import Tagged

public struct Device: Equatable, Identifiable, Codable {

    public struct DeviceChild: Equatable, Identifiable, Codable {
        public init(
            id: Id,
            name: String,
            state: RelayIsOn
        ) {
            self.id = id
            self.name = name
            self.state = state
        }

        public let id: Id
        public let name: String
        public var state: RelayIsOn
    }

    public init(
        id: Id,
        name: String,
        children: [DeviceChild] = [],
        state: RelayIsOn?
    ) {
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
}

extension Device {

    public static let debugDevice1 = Self(id: "1", name: "Test device 1", state: false)
    public static let debugDevice2 = Self(id: "2", name: "Test device 2", state: true)
    public static let debugDevice3 = Self(
        id: "3",
        name: "Test device 3",
        children: [
            .init(id: "Child 1-3", name: "Child 1 of device 3", state: true),
            .init(id: "Child 2-3", name: "Child 2 of device 3", state: false),
        ],
        state: false
    )
}

public struct FlattenDevice: Equatable, Identifiable {
    public struct DoubleID: Equatable, Hashable {

        public init(
            parent: Device.ID,
            child: Device.ID?
        ) {
            self.child = child
            self.parent = parent
        }

        public let parent: Device.ID
        public let child: Device.ID?

        public func added() -> String {
            return parent.rawValue + (child?.rawValue ?? "")
        }
    }

    public init(
        device: Device,
        child: Device.DeviceChild?
    ) {
        self.device = device
        self.child = child
    }

    public var id: DoubleID { .init(parent: self.device.id, child: self.child?.id) }
    public let device: Device
    public let child: Device.DeviceChild?
}

extension [Device] {
    public func flatten() -> [FlattenDevice] {
        var entries: [FlattenDevice] = []
        entries.reserveCapacity(self.count)
        for device in self {
            if device.children.isEmpty {
                entries.append(FlattenDevice(device: device, child: nil))
            } else {
                entries.append(contentsOf: device.children.map { FlattenDevice(device: device, child: $0) })
            }
        }
        return entries
    }
}

public enum DevicesLink: Equatable {
    case device(Device.ID, Device.Link)
    case closeAll
}

extension Device {
    public enum Link: Equatable {
        case child(Device.ID, Device.DeviceChild.Link)
        case toggle
    }
}

extension Device.DeviceChild {
    public enum Link: Equatable {
        case toggle
    }
}
