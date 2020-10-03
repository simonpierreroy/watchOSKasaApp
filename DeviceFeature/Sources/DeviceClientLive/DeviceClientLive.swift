import KasaNetworking
import DeviceClient
import ComposableArchitecture
import Combine
import KasaCore
#if canImport(WidgetKit)
import WidgetKit
#endif

extension Device.ID {
    func networkDeviceID() -> Networking.App.DeviceID {
        return .init(rawValue: self.rawValue)
    }
}

public extension DeviceDetailEvironment {
    static func liveToggleDeviceState(token : Token, id: Device.ID) -> AnyPublisher<RelayIsOn, Error> {
        return Networking.App
            .toggleDevicesState(token: token, id: id.networkDeviceID())
            .eraseToAnyPublisher()
    }
}

extension Device {
    init(kasa: Networking.App.KasaDevice) {
        self.init(id: .init(rawValue: kasa.deviceId), name: kasa.alias)
    }
}

public extension DevicesEnvironment {
    static func liveDevicesCall(token: Token) -> AnyPublisher<[Device], Error> {
        return Networking.App
            .getDevices(token: token)
            .map(\.deviceList)
            .map(map(Device.init(kasa:)))
            .eraseToAnyPublisher()
    }
}

public extension DevicesEnvironment {
    static func liveChangeDevicesState(token:Token, id: Device.ID, newState: RelayIsOn) -> AnyPublisher<RelayIsOn, Error> {
        Networking.App
            .changeDevicesState(token: token, id: id.networkDeviceID(), state: newState)
    }
}

public extension DevicesEnvironment {
    static func liveGetDevicesState(token:Token, id: Device.ID) -> AnyPublisher<RelayIsOn, Error> {
        Networking.App
            .getDevicesState(token: token, id: id.networkDeviceID())
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
            #if canImport(WidgetKit)
                WidgetCenter.shared.reloadAllTimelines()
            #endif
        }.eraseToAnyPublisher()
    }
    
    
    static let liveLoadCache: AnyPublisher<[Device], Error> = Effect.catching {
        
        let data = try
            UserDefaults.kasaAppGroup.string(forKey: "cacheDevices")?.data(using: .utf8)
            .map { try decoder.decode([Device].self, from: $0) }
        
        return data ?? []
    }.eraseToAnyPublisher()
}

