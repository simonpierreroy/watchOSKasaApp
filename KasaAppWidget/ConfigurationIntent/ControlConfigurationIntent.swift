//
//  ControlConfigurationIntent.swift
//  KasaAppWidgetExtension
//
//  Created by Simon-Pierre Roy on 9/20/24.
//  Copyright © 2024 Simon. All rights reserved.
//

import AppIntents
import Foundation

struct SelectDevicesControlConfigurationIntent: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "title_intent_select_device"
    static let description = IntentDescription("description_select_device")

    @Parameter(title: "list_for_select_devices_intent")
    var selectedDevice: SelectedDeviceAppEntity?
}
