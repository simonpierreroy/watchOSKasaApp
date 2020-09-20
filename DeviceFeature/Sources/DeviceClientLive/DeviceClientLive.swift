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

