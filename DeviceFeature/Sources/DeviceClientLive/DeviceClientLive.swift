import Combine
import ComposableArchitecture
import DeviceClient
import Foundation
import KasaCore
import KasaNetworking

extension DevicesClient: DependencyKey {
    public static let liveValue = DevicesClient(
        loadDevices: getDevicesCall,
        toggleDeviceRelayState: toggleDeviceRelayState(token:id:childId:),
        getDeviceRelayState: getDeviceRelayState(token:id:childId:),
        changeDeviceRelayState: changeDeviceRelayState(token:id:childId:newState:)
    )
}

extension Device.ID {
    fileprivate func networkDeviceID() -> Networking.App.DeviceID {
        return .init(rawValue: self.rawValue)
    }
}

extension Device {
    fileprivate init(
        kasa: Networking.App.KasaDeviceAndSystemInfo
    ) throws {

        let infoState: Device.State
        let children: [Networking.App.KasaChildrenDevice]
        switch kasa.info {
        case .success(let data):
            let info = Device.Info.init(
                softwareVersion: .init(data.softwareVersion),
                hardwareVersion: .init(data.hardwareVersion),
                model: .init(data.model),
                macAddress: .init(data.mac)
            )
            if let relayState = data.relayState {
                let relay = try Networking.App.getRelayState(from: relayState)
                infoState = .status(relay: relay, info: info)
            } else {
                infoState = .noRelay(info: info)
            }
            children = data.children ?? []
        case .failure(let error):
            infoState = .failed(.init(code: error.code, message: error.message))
            children = []
        }

        self.init(
            id: .init(rawValue: kasa.device.deviceId.rawValue),
            name: kasa.device.alias.rawValue,
            children:
                try children
                .map {
                    Device.DeviceChild(
                        id: .init(rawValue: $0.id.rawValue),
                        name: $0.alias.rawValue,
                        state: try Networking.App.getRelayState(from: $0.state)
                    )
                },
            details: infoState
        )
    }
}

@Sendable
private func toggleDeviceRelayState(token: Token, id: Device.ID, childId: Device.ID?) async throws -> RelayIsOn {
    return try await Networking.App
        .toggleDeviceRelayState(
            token: token,
            id: id.networkDeviceID(),
            childId: childId?.networkDeviceID()
        )
}

@Sendable
private func getDevicesCall(token: Token) async throws -> [Device] {
    let devicesData = try await Networking.App.getDevicesAndSysInfo(token: token)
    return try devicesData.map(Device.init(kasa:))
}

@Sendable
private func changeDeviceRelayState(
    token: Token,
    id: Device.ID,
    childId: Device.ID?,
    newState: RelayIsOn
) async throws -> RelayIsOn {
    return try await Networking.App.changeDeviceRelayState(
        token: token,
        id: id.networkDeviceID(),
        childId: childId?.networkDeviceID(),
        state: newState
    )
}

@Sendable
private func getDeviceRelayState(token: Token, id: Device.ID, childId: Device.ID?) async throws -> RelayIsOn {
    return try await Networking.App.tryToGetDeviceRelayState(
        token: token,
        id: id.networkDeviceID(),
        childId: childId?.networkDeviceID()
    )
}
