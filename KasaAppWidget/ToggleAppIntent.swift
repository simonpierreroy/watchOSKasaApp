//
//  ToggleAppIntent.swift
//
//
//  Created by Simon-Pierre Roy on 9/20/23.
//

import AppIntents
import Dependencies
import DeviceClient
import Foundation
import UserClient

struct ToggleAppIntent: AppIntent {

    static var title: LocalizedStringResource = "title_toggle_app_intent"

    static var parameterSummary: some ParameterSummary {
        Summary("Toggle \(\.$deviceEntity)")
    }

    @Dependencies.Dependency(\.devicesClient.toggleDeviceRelayState) var toggleDeviceRelayState
    @Dependencies.Dependency(\.devicesClient.changeDeviceRelayState) var changeDeviceRelayState
    @Dependencies.Dependency(\.userCache.load) var loadUser
    @Dependencies.Dependency(\.devicesCache.load) var loadDevices

    init() {}

    init(flattenDevice: FlattenDevice?) {
        self.deviceEntity = flattenDevice.map(SelectedDeviceAppEntity.init(flattenDevice:))
    }

    @Parameter(title: "device_toggle_app_intent")
    var deviceEntity: SelectedDeviceAppEntity?

    func perform() async throws -> some IntentResult {
        guard let user = try? await self.loadUser(),
            let devices = try? await self.loadDevices()
        else { return .result() }

        if let deviceEntity {
            let foundDevices = Device.flattenSearch(devices: devices, identifiers: [deviceEntity.id])
            guard foundDevices.count == 1, let foundDevice = foundDevices.first else { return .result() }
            _ = try? await self.toggleDeviceRelayState(
                user.tokenInfo.token,
                foundDevice.device.id,
                foundDevice.child?.id
            )
        } else {
            let flattenList = devices.flatten()
            for device in flattenList {
                _ = try? await self.changeDeviceRelayState(
                    user.tokenInfo.token,
                    device.device.id,
                    device.child?.id,
                    false
                )
            }
        }
        return .result()
    }
}
