//
//  Inte.swift
//  KasaWatchWidgetExtensionExtension
//
//  Created by Simon-Pierre Roy on 9/18/24.
//  Copyright © 2024 Simon. All rights reserved.
//

import AppIntents
import Dependencies
import DeviceClient
import Foundation
import UserClient

struct TurnOffAppIntent: AppIntent {

    static let title: LocalizedStringResource = "title_toggle_app_intent"

    @Dependencies.Dependency(\.devicesClient.changeDeviceRelayState) var changeDeviceRelayState
    @Dependencies.Dependency(\.userCache.load) var loadUser
    @Dependencies.Dependency(\.devicesCache.load) var loadDevices

    init() {}

    func perform() async throws -> some IntentResult {
        guard let user = try? await self.loadUser(),
            let devices = try? await self.loadDevices()
        else { return .result() }

        let flattenList = devices.flatten()
        for device in flattenList {
            _ = try? await self.changeDeviceRelayState(
                user.tokenInfo.token,
                device.device.id,
                device.child?.id,
                false
            )
        }

        return .result()
    }
}
