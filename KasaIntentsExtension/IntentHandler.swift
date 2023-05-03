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

final class IntentHandler: INExtension {

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
            let selected = SelectedDevice(
                identifier: $0.id(),
                display: $0.child?.name ?? $0.device.name
            )
            selected.childId = $0.child?.id.rawValue
            selected.deviceId = $0.device.id.rawValue
            return selected
        }
        return INObjectCollection(items: options)
    }
}
