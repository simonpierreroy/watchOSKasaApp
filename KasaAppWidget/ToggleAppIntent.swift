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
    static var description = IntentDescription("description_toggle_app_intent")

    @Dependencies.Dependency(\.devicesClient.toggleDeviceRelayState) var toggleDeviceRelayState
    @Dependencies.Dependency(\.devicesClient.changeDeviceRelayState) var changeDeviceRelayState
    @Dependencies.Dependency(\.userCache.load) var loadUser
    @Dependencies.Dependency(\.devicesCache.load) var loadDevices

    init() {}

    init(flattenDevice: FlattenDevice?) {
        self.parentId = flattenDevice?.device.id.rawValue
        self.childId = flattenDevice?.child?.id.rawValue
    }

    @Parameter(title: "parent_toggle_app_intent")
    var parentId: String?

    @Parameter(title: "child_toggle_app_intent")
    var childId: String?

    func perform() async throws -> some IntentResult {
        guard let user = try? await self.loadUser() else { return .result() }

        if let parentId {
            _ = try? await self.toggleDeviceRelayState(
                user.tokenInfo.token,
                .init(parentId),
                childId.map(Device.Id.init(rawValue:))
            )
        } else {
            guard let devices = try? await self.loadDevices() else { return .result() }
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
