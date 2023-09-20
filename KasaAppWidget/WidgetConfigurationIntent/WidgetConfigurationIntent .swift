//
//  WidgetConfigurationIntent.swift
//  Kasa
//
//  Created by Simon-Pierre Roy on 9/18/23.
//  Copyright © 2023 Simon. All rights reserved.
//

import AppIntents
import Foundation

struct SelectDevicesWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "SelectDevices"
    static var description = IntentDescription("description_intent")

    @Parameter(
        title: "devices_intent",
        default: [],
        size: [
            .systemSmall: 1,
            .systemMedium: 4,
            .systemLarge: 6,
            .systemExtraLarge: 8,
            .accessoryInline: 1,
            .accessoryCorner: 1,
            .accessoryCircular: 1,
            .accessoryRectangular: 1,
        ]
    )
    var selectedDevice: [SelectedDeviceAppEntity]
}
