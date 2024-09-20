//
//  KasaAppWidgetWithAppIntent.swift
//  KasaAppWidgetExtension
//
//  Created by Simon-Pierre Roy on 9/20/24.
//  Copyright © 2024 Simon. All rights reserved.
//

import SwiftUI
import WidgetClient
import WidgetClientLive
import WidgetFeature
import WidgetKit

struct AppIntentWidgetProvider: AppIntentTimelineProvider {
    let config = ProviderConfig()

    func placeholder(in context: Context) -> DataDeviceEntry {
        .preview(10)
    }

    func snapshot(
        for configuration: SelectDevicesWidgetConfigurationIntent,
        in context: Context
    ) async -> DataDeviceEntry {
        return newEntry(
            cache: .init(loadDevices: config.loadDevices, loadUser: config.loadUser),
            intentSelection: nil
        )
    }

    func timeline(
        for configuration: SelectDevicesWidgetConfigurationIntent,
        in context: Context
    ) async -> Timeline<DataDeviceEntry> {
        let selection = configuration.selectedDevice.map(\.id)

        let entry = newEntry(
            cache: .init(loadDevices: config.loadDevices, loadUser: config.loadUser),
            intentSelection: selection
        )

        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .hour, value: 24, to: currentDate)!

        return Timeline(
            entries: [entry],
            policy: .after(entryDate)
        )
    }
}

struct KasaAppWidgetWithAppIntent: Widget {
    let kind: String = "KasaAppWidgetWithAppIntent"
    let provider = AppIntentWidgetProvider()

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectDevicesWidgetConfigurationIntent.self,
            provider: provider
        ) { entry in
            KasaAppWidgetEntryView(
                entry: entry,
                newIntent: ToggleAppIntent.init(flattenDevice:),
                getURL: provider.config.render(link:),
                mode: .selectableMultiDevices
            )
        }.promptsForUserConfiguration()
            .supportedFamilies([.systemExtraLarge, .systemLarge, .systemMedium, .systemSmall])
            .configurationDisplayName("Kasa Devices")
            .description(WidgetFeature.Strings.descriptionWidget.string)
    }
}

#Preview("systemSmall", as: .systemSmall) {
    KasaAppWidgetWithAppIntent()
} timeline: {
    DataDeviceEntry.previewLogout
    DataDeviceEntry.previewNoDevice
    DataDeviceEntry.preview(1)
    DataDeviceEntry.preview(2)
    DataDeviceEntry.preview(3)
    DataDeviceEntry.preview(8)
}

#Preview("systemMedium", as: .systemMedium) {
    KasaAppWidgetWithAppIntent()
} timeline: {
    DataDeviceEntry.previewLogout
    DataDeviceEntry.previewNoDevice
    DataDeviceEntry.preview(1)
    DataDeviceEntry.preview(2)
    DataDeviceEntry.preview(3)
    DataDeviceEntry.preview(8)
}

#Preview("systemLarge", as: .systemLarge) {
    KasaAppWidgetWithAppIntent()
} timeline: {
    DataDeviceEntry.previewLogout
    DataDeviceEntry.previewNoDevice
    DataDeviceEntry.preview(1)
    DataDeviceEntry.preview(2)
    DataDeviceEntry.preview(3)
    DataDeviceEntry.preview(8)
}
