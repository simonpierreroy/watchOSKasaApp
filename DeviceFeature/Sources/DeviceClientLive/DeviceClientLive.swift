import KasaNetworking
import DeviceClient
import ComposableArchitecture
import Combine
import KasaCore
import Foundation

extension DevicesClient: DependencyKey {
    public static let liveValue = DevicesClient(
        loadDevices: getDevicesCall,
        toggleDeviceRelayState: toggleDeviceRelayState(token:id:childId:),
        getDeviceRelayState: getDeviceRelayState(token:id:childId:),
        changeDeviceRelayState: changeDeviceRelayState(token:id:childId:newState:)
    )
}

private extension Device.ID {
    func networkDeviceID() -> Networking.App.DeviceID {
        return .init(rawValue: self.rawValue)
    }
}

private extension Device {
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

@Sendable
private func toggleDeviceRelayState(token : Token, id: Device.ID, childId: Device.ID?) async throws -> RelayIsOn {
    return try await Networking.App
        .toggleDeviceRelayState(
            token: token,
            id: id.networkDeviceID(),
            childId: childId?.networkDeviceID()
        )
}

@Sendable
private func getDevicesCall(token: Token) async throws-> [Device] {
    let devicesData = try await Networking.App.getDevicesAndSysInfo(token: token)
    return try devicesData.map(Device.init(kasa:))
}

@Sendable
private func changeDeviceRelayState(token:Token, id: Device.ID, childId: Device.ID?, newState: RelayIsOn) async throws-> RelayIsOn {
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
