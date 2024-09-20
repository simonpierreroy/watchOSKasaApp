//
//  KasaWatchWidgetExtension.swift
//  KasaWatchWidgetExtension
//
//  Created by Simon-Pierre Roy on 5/3/23.
//  Copyright © 2023 Simon. All rights reserved.
//

import SwiftUI
import WidgetClient
import WidgetClientLive
import WidgetFeature
import WidgetKit

struct StaticProvider: TimelineProvider {

    let config = ProviderConfig()

    func placeholder(in context: Context) -> DataDeviceEntry {
        .preview(1)
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

struct KasaWatchWidgetStatic: Widget {
    let kind: String = "KasaWatchWidgetStatic"
    var body: some WidgetConfiguration {
        let provider = StaticProvider()

        return StaticConfiguration(
            kind: kind,
            provider: provider
        ) { entry in
            KasaAppWidgetEntryView(
                entry: entry,
                newIntent: { _ in TurnOffAppIntent() },
                getURL: provider.config.render(link:),
                mode: .turnOffAllDevices
            )
        }
        .configurationDisplayName("Kasa")
        .description(WidgetFeature.Strings.descriptionWidget.string)

    }
}

#Preview("accessoryCorner", as: .accessoryCorner) {
    KasaWatchWidgetStatic()
} timeline: {
    DataDeviceEntry.previewLogout
    DataDeviceEntry.previewNoDevice
    DataDeviceEntry.preview(1)
    DataDeviceEntry.preview(3)
}

#Preview("accessoryInline", as: .accessoryInline) {
    KasaWatchWidgetStatic()
} timeline: {
    DataDeviceEntry.previewLogout
    DataDeviceEntry.previewNoDevice
    DataDeviceEntry.preview(1)
    DataDeviceEntry.preview(3)
}

#Preview("accessoryRectangular", as: .accessoryRectangular) {
    KasaWatchWidgetStatic()
} timeline: {
    DataDeviceEntry.previewLogout
    DataDeviceEntry.previewNoDevice
    DataDeviceEntry.preview(1)
    DataDeviceEntry.preview(3)
}

#Preview("accessoryCircular", as: .accessoryCircular) {
    KasaWatchWidgetStatic()
} timeline: {
    DataDeviceEntry.previewLogout
    DataDeviceEntry.previewNoDevice
    DataDeviceEntry.preview(1)
    DataDeviceEntry.preview(3)
}
