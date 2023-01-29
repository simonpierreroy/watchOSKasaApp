//
//  IntentHandler.swift
//  KasaIntentsExtension
//
//  Created by Simon-Pierre Roy on 11/22/22.
//  Copyright © 2022 Simon. All rights reserved.
//

import Dependencies
import DeviceClient
import Intents
import WidgetClient
import WidgetClientLive
import WidgetFeature

class IntentHandler: INExtension {

    @Dependency(\.userCache.loadBlocking) var loadUser
    @Dependency(\.devicesCache.loadBlocking) var loadDevices

    override func handler(for intent: INIntent) -> Any {
        return self
    }

}

extension IntentHandler: SelectDevicesIntentHandling {
    func provideSelectedDeviceOptionsCollection(
        for intent: SelectDevicesIntent
    ) async throws -> INObjectCollection<SelectedDevice> {
        guard
            let cache = try? getCacheState(cache: .init(loadDevices: loadDevices, loadUser: loadUser)),
            cache.user != nil
        else {
            return INObjectCollection(items: [])
        }

        let cachedDevices = cache.device.flatten()
        let options = cachedDevices.map {
            let seledted = SelectedDevice(
                identifier: $0.id.added(),
                display: $0.child?.name ?? $0.device.name
            )
            seledted.childId = $0.child?.id.rawValue
            seledted.deviceId = $0.device.id.rawValue
            return seledted
        }
        return INObjectCollection(items: options)
    }
}