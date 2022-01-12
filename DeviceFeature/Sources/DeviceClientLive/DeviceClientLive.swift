import KasaNetworking
import DeviceClient
import ComposableArchitecture
import Combine
import KasaCore

extension Device.ID {
    func networkDeviceID() -> Networking.App.DeviceID {
        return .init(rawValue: self.rawValue)
    }
}

public extension DeviceDetailEvironment {
    static func liveToggleDeviceRelayState(token : Token, id: Device.ID) -> AnyPublisher<RelayIsOn, Error> {
        return Effect.task {
            return try await Networking.App.toggleDeviceRelayState(token: token, id: id.networkDeviceID())
        }.eraseToAnyPublisher()
    }
}

extension Device {
    init(kasa: Networking.App.KasaDevice) {
        self.init(id: .init(rawValue: kasa.deviceId.rawValue), name: kasa.alias.rawValue)
    }
}

public extension DevicesEnvironment {
    static func liveDevicesCall(token: Token) -> AnyPublisher<[Device], Error> {
        return Effect.task {
            let devicesData = try await Networking.App.getDevices(token: token)
            return devicesData.deviceList.map(Device.init(kasa:))
        }.eraseToAnyPublisher()
    }
}

public extension DevicesEnvironment {
    static func liveChangeDeviceRelayState(token:Token, id: Device.ID, newState: RelayIsOn) -> AnyPublisher<RelayIsOn, Error> {
        return Effect.task {
            return try await Networking.App.changeDeviceRelayState(token: token, id: id.networkDeviceID(), state: newState)
        }.eraseToAnyPublisher()
    }
}

public extension DevicesEnvironment {
    static func liveGetDeviceRelayState(token:Token, id: Device.ID) -> AnyPublisher<RelayIsOn, Error> {
        return Effect.task {
            return try await Networking.App.tryToGetDeviceRelayState(token: token, id: id.networkDeviceID())
        }.eraseToAnyPublisher()
    }
}

public extension DevicesEnvironment {
    
    static let encoder = JSONEncoder()
    static let decoder = JSONDecoder()
    
    static func liveSave(devices: [Device]) -> AnyPublisher<Void, Error> {
        return Effect.catching {
            let data = try encoder.encode(devices)
            let string = String(data: data, encoding: .utf8)
            UserDefaults.kasaAppGroup.setValue(string, forKeyPath: "cacheDevices")
        }.eraseToAnyPublisher()
    }
    
    
    static let liveLoadCache: AnyPublisher<[Device], Error> = Effect.catching {
        let data = try UserDefaults.kasaAppGroup
            .string(forKey: "cacheDevices")?
            .data(using: .utf8)
            .map { try decoder.decode([Device].self, from: $0) }
        return data ?? []
    }.eraseToAnyPublisher()
}

public extension DevicesCache {
    static let live = Self(save: DevicesEnvironment.liveSave(devices:), load: DevicesEnvironment.liveLoadCache)
}

public extension DevicesRepo {
    static let live = Self(
        loadDevices: DevicesEnvironment.liveDevicesCall(token:),
        toggleDeviceRelayState: DeviceDetailEvironment.liveToggleDeviceRelayState,
        getDeviceRelayState: DevicesEnvironment.liveGetDeviceRelayState(token:id:),
        changeDeviceRelayState: DevicesEnvironment.liveChangeDeviceRelayState(token:id:newState:)
    )
}

public extension Link.URLParser {
    static let live = Self(parse: Link.parserDeepLink(url:))
}

