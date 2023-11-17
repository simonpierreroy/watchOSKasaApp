import CasePaths
import Combine
import ComposableArchitecture
import Foundation
import KasaCore
import Tagged

public struct Device: Equatable, Identifiable, Codable, Sendable {

    public struct Info: Equatable, Codable, Sendable {

        public init(
            softwareVersion: SoftwareVersion,
            hardwareVersion: HardwareVersion,
            model: Model,
            macAddress: Mac
        ) {
            self.softwareVersion = softwareVersion
            self.hardwareVersion = hardwareVersion
            self.model = model
            self.macAddress = macAddress
        }

        //Shared Types
        public struct SoftwareVersionTag {}
        public typealias SoftwareVersion = Tagged<Self.SoftwareVersionTag, String>
        public struct HardwareVersionTag {}
        public typealias HardwareVersion = Tagged<Self.HardwareVersionTag, String>
        public struct ModelTag {}
        public typealias Model = Tagged<Self.ModelTag, String>
        public struct MacTag {}
        public typealias Mac = Tagged<Self.ModelTag, String>

        public let softwareVersion: SoftwareVersion
        public let hardwareVersion: HardwareVersion
        public let model: Model
        public let macAddress: Mac
    }

    public struct DeviceChild: Equatable, Identifiable, Codable, Sendable {
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
        details: State
    ) {
        self.id = id
        self.name = name
        self.children = children
        self.details = details
    }

    public typealias Id = Tagged<Device, String>

    public struct Failed: Equatable, Codable, Sendable {
        public init(
            code: Int,
            message: String
        ) {
            self.code = code
            self.message = message
        }
        public let code: Int
        public let message: String
    }

    @CasePathable
    @dynamicMemberLookup
    public enum State: Equatable, Codable, Sendable {
        case status(relay: RelayIsOn, info: Info)
        case noRelay(info: Info)
        case failed(Failed)

        public var info: Info? {
            switch self {
            case .noRelay(let info), .status(relay: _, let info):
                return info
            case .failed:
                return nil
            }
        }
    }

    public let id: Id
    public let name: String
    public let children: [DeviceChild]
    public var details: State
}

extension Device.Info {
    public static let mock = Device.Info(
        softwareVersion: "1.2.3",
        hardwareVersion: "9.8.7",
        model: "HS123",
        macAddress: "123456789"
    )
}

extension Device {

    public static let debug1 = Self(id: "1", name: "Test device 1", details: .status(relay: false, info: .mock))
    public static let debug2 = Self(id: "2", name: "Test device 2", details: .status(relay: true, info: .mock))
    public static let debug3 = Self(
        id: "3",
        name: "Test device 3",
        children: [
            .init(id: "Child 1-3", name: "Child 1 of device 3", state: true),
            .init(id: "Child 2-3", name: "Child 2 of device 3", state: false),
        ],
        details: .status(relay: false, info: .mock)
    )
}

extension Device {
    public static func flattenSearch(devices: [Self], identifiers: [FlattenDevice.ID]) -> [FlattenDevice] {
        let devicesWithId = IdentifiedArray(uniqueElements: devices.flatten())
        return identifiers.compactMap { devicesWithId[id: $0] }
    }
}

public struct FlattenDevice: Equatable, Identifiable, Sendable {
    public struct ID: Equatable, Hashable, Sendable {

        public init(
            parent: Device.ID,
            child: Device.ID?
        ) {
            self.rawValue = child?.rawValue ?? parent.rawValue
        }

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public let rawValue: String
    }

    public init(
        device: Device,
        child: Device.DeviceChild?
    ) {
        self.device = device
        self.child = child
    }

    public var id: ID { .init(parent: self.device.id, child: self.child?.id) }
    public let device: Device
    public let child: Device.DeviceChild?

    public var displayName: String {
        self.child?.name ?? self.device.name
    }
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
    case turnOffAllDevices
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
