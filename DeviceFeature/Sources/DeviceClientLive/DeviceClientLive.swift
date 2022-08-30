import KasaNetworking
import DeviceClient
import ComposableArchitecture
import Combine
import KasaCore
import Foundation

extension Device.ID {
    func networkDeviceID() -> Networking.App.DeviceID {
        return .init(rawValue: self.rawValue)
    }
}

public extension DeviceDetailEvironment {
    @Sendable
    static func liveToggleDeviceRelayState(token : Token, id: Device.ID, childId: Device.ID?) async throws -> RelayIsOn {
        return try await Networking.App
            .toggleDeviceRelayState(
                token: token,
                id: id.networkDeviceID(),
                childId: childId?.networkDeviceID()
            )
    }
}

extension Device {
    init(kasa: Networking.App.KasaDeviceAndSystemInfo) throws {
        let infoState: RelayIsOn?
        if let relay_state = kasa.info.relay_state {
            infoState = try Networking.App.getRelayState(from: relay_state)
        } else { infoState = nil }
        
        self.init(
            id: .init(rawValue: kasa.device.deviceId.rawValue),
            name: kasa.device.alias.rawValue,
            children: try (kasa.info.children ?? [])
                .map{
                    Device.DeviceChild(
                        id: .init(rawValue: $0.id.rawValue),
                        name: $0.alias.rawValue,
                        state: try Networking.App.getRelayState(from: $0.state)
                    )
                },
            state: infoState
        )
    }
}

public extension DevicesEnvironment {
    @Sendable
    static func liveDevicesCall(token: Token) async throws-> [Device] {
        let devicesData = try await Networking.App.getDevicesAndSysInfo(token: token)
        return try devicesData.map(Device.init(kasa:))
    }
}

public extension DevicesEnvironment {
    @Sendable
    static func liveChangeDeviceRelayState(token:Token, id: Device.ID, childId: Device.ID?, newState: RelayIsOn) async throws-> RelayIsOn {
        return try await Networking.App.changeDeviceRelayState(
            token: token,
            id: id.networkDeviceID(),
            childId: childId?.networkDeviceID(),
            state: newState
        )
    }
}

public extension DevicesEnvironment {
    @Sendable
    static func liveGetDeviceRelayState(token: Token, id: Device.ID, childId: Device.ID?) async throws -> RelayIsOn {
        return try await Networking.App.tryToGetDeviceRelayState(
            token: token,
            id: id.networkDeviceID(),
            childId: childId?.networkDeviceID()
        )
    }
}

public extension DevicesEnvironment {
    
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()
    private static let deviceKey: String = "cacheDevices"
    
    @Sendable
    static func liveSave(devices: [Device]) async throws -> Void {
        let data = try encoder.encode(devices)
        let string = String(data: data, encoding: .utf8)
        UserDefaults.kasaAppGroup.setValue(string, forKeyPath: DevicesEnvironment.deviceKey)
    }
    
    @Sendable
    static func liveloadBlockingCache() throws -> [Device] {
        guard let stringData = UserDefaults.kasaAppGroup.string(forKey: DevicesEnvironment.deviceKey) else {
            return []
        }
        
        guard let data = stringData.data(using: .utf8) else {
            throw DevicesCache.Failure.dataConversion
        }
        return try decoder.decode([Device].self, from: data)
    }
    
    @Sendable
    static func liveLoadCache() async throws -> [Device] {
        return try DevicesEnvironment.liveloadBlockingCache()
    }
}

public extension DevicesCache {
    static let live = Self(
        save: DevicesEnvironment.liveSave(devices:),
        load: DevicesEnvironment.liveLoadCache,
        loadBlocking: DevicesEnvironment.liveloadBlockingCache
    )
}

public extension DevicesRepo {
    static let live = Self(
        loadDevices: DevicesEnvironment.liveDevicesCall(token:),
        toggleDeviceRelayState: DeviceDetailEvironment.liveToggleDeviceRelayState,
        getDeviceRelayState: DevicesEnvironment.liveGetDeviceRelayState(token:id:childId:),
        changeDeviceRelayState: DevicesEnvironment.liveChangeDeviceRelayState(token:id:childId:newState:)
    )
}
