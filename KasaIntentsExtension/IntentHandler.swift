//
//  IntentHandler.swift
//  KasaIntentsExtension
//
//  Created by Simon-Pierre Roy on 11/22/22.
//  Copyright © 2022 Simon. All rights reserved.
//

import Intents
import WidgetFeature
import WidgetClientLive
import WidgetClient
import DeviceClient
import Dependencies

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
            cache.user != nil else {
            return  INObjectCollection(items: [])
        }
        
        let options = cache.device.map {
            SelectedDevice(identifier: $0.id.rawValue, display: $0.name)
        }
        return INObjectCollection(items: options)
    }
}
