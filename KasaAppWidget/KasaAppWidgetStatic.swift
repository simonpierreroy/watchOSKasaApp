//
//  KasaAppWidgetStatic.swift
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

struct KasaAppWidgetStatic: Widget {
    let kind: String = "KasaAppWidgetStatic"
    let provider = StaticWidgetProvider()

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: provider
        ) { entry in
            KasaAppWidgetEntryView(
                entry: entry,
                newIntent: ToggleAppIntent.init(flattenDevice:),
                getURL: provider.config.render(link:),
                mode: .turnOffAllDevices
            )
        }
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline, .accessoryRectangular])
        .configurationDisplayName("Kasa Turn Off")
        .description(WidgetFeature.Strings.descriptionWidget.string)

    }
}

struct StaticWidgetProvider: TimelineProvider {
    let config = ProviderConfig()

    func placeholder(in context: Context) -> DataDeviceEntry {
        .preview(10)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetClient.DataDeviceEntry) -> Void) {
        completion(
            newEntry(
                cache: .init(loadDevices: config.loadDevices, loadUser: config.loadUser),
                intentSelection: nil
            )
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetClient.DataDeviceEntry>) -> Void) {
        let entry = newEntry(
            cache: .init(loadDevices: config.loadDevices, loadUser: config.loadUser),
            intentSelection: nil
        )
        let timeline = Timeline(
            entries: [entry],
            policy: .never
        )
        completion(timeline)
    }
}

#Preview("accessoryRectangular", as: .accessoryInline) {
    KasaAppWidgetStatic()
} timeline: {
    DataDeviceEntry.previewLogout
    DataDeviceEntry.previewNoDevice
    DataDeviceEntry.preview(1)
}

#Preview("accessoryRectangular", as: .accessoryRectangular) {
    KasaAppWidgetStatic()
} timeline: {
    DataDeviceEntry.previewLogout
    DataDeviceEntry.previewNoDevice
    DataDeviceEntry.preview(1)
}

#Preview("systemSmall", as: .systemSmall) {
    KasaAppWidgetStatic()
} timeline: {
    DataDeviceEntry.previewLogout
    DataDeviceEntry.previewNoDevice
    DataDeviceEntry.preview(1)
}
