//
//  KasaAppWidget.swift
//  KasaAppWidget
//
//  Created by Simon-Pierre Roy on 10/3/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Combine
import DeviceClient
import RoutingClient
import RoutingClientLive
import SwiftUI
import WidgetClient
import WidgetClientLive
import WidgetFeature
import WidgetKit

struct StaticProvider: TimelineProvider {
    let config = ProviderConfig()

    func placeholder(in context: Context) -> DataDeviceEntry {
        .preview(10)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetClient.DataDeviceEntry) -> Void) {
        completion(
            newEntry(
                cache: .init(loadDevices: config.loadDevices, loadUser: config.loadUser),
                intentSelection: nil,
                for: context
            )
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetClient.DataDeviceEntry>) -> Void) {
        let entry = newEntry(
            cache: .init(loadDevices: config.loadDevices, loadUser: config.loadUser),
            intentSelection: nil,
            for: context
        )
        let timeline = Timeline(
            entries: [entry],
            policy: .never
        )
        completion(timeline)
    }
}

struct AppIntentProvider: AppIntentTimelineProvider {
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
            intentSelection: nil,
            for: context
        )
    }

    func timeline(
        for configuration: SelectDevicesWidgetConfigurationIntent,
        in context: Context
    ) async -> Timeline<DataDeviceEntry> {
        let selection = configuration.selectedDevice.map(\.id)

        let entry = newEntry(
            cache: .init(loadDevices: config.loadDevices, loadUser: config.loadUser),
            intentSelection: selection,
            for: context
        )

        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .hour, value: 24, to: currentDate)!

        return Timeline(
            entries: [entry],
            policy: .after(entryDate)
        )
    }
}

@main
struct KasaAppWidgets: WidgetBundle {

    @WidgetBundleBuilder
    var body: some Widget {
        KasaAppWidgetWithAppIntent()
        KasaAppWidgetStatic()
    }
}

struct KasaAppWidgetWithAppIntent: Widget {
    let kind: String = "KasaAppWidgetWithAppIntent"
    let provider = AppIntentProvider()

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
        }
        .supportedFamilies([.systemExtraLarge, .systemLarge, .systemMedium, .systemSmall])
        .configurationDisplayName("Kasa 1")
        .description(WidgetFeature.Strings.descriptionWidget.string)
    }
}

struct KasaAppWidgetStatic: Widget {
    let kind: String = "KasaAppWidgetStatic"
    let provider = StaticProvider()

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
        .configurationDisplayName("Kasa 2")
        .description(WidgetFeature.Strings.descriptionWidget.string)

    }
}

#Preview(as: .systemMedium) {
    KasaAppWidgetWithAppIntent()
} timeline: {
    DataDeviceEntry.previewLogout
    DataDeviceEntry.previewNoDevice
    DataDeviceEntry.preview(1)
    DataDeviceEntry.preview(2)
    DataDeviceEntry.preview(3)
    DataDeviceEntry.preview(8)
}

#Preview(as: .accessoryRectangular) {
    KasaAppWidgetStatic()
} timeline: {
    DataDeviceEntry.previewLogout
    DataDeviceEntry.previewNoDevice
    DataDeviceEntry.preview(1)
}
