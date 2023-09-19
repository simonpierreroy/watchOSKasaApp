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

extension SelectDevicesIntent {
    func getIds() -> [FlattenDevice.DoubleID] {
        guard let selections = self.SelectedDevice else {
            return []
        }

        var result: [FlattenDevice.DoubleID] = []

        for selection in selections {
            guard let pID = selection.deviceId else { break }
            let cID = selection.childId.map { id in Device.ID.init(rawValue: id) }
            result.append(
                .init(parent: .init(rawValue: pID), child: cID)
            )
        }

        return result
    }
}

struct IntentProvider: IntentTimelineProvider {

    let config = ProviderConfig()

    func placeholder(in context: Context) -> DataDeviceEntry {
        .preview(10)
    }

    func getSnapshot(
        for configuration: SelectDevicesIntent,
        in context: Context,
        completion: @escaping (DataDeviceEntry) -> Void
    ) {
        completion(
            newEntry(
                cache: .init(loadDevices: config.loadDevices, loadUser: config.loadUser),
                intentSelection: nil,
                for: context
            )
        )
    }

    func getTimeline(
        for configuration: SelectDevicesIntent,
        in context: Context,
        completion: @escaping (Timeline<Entry>) -> Void
    ) {
        let selection = configuration.getIds()

        let entry = newEntry(
            cache: .init(loadDevices: config.loadDevices, loadUser: config.loadUser),
            intentSelection: selection,
            for: context
        )
        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .hour, value: 24, to: currentDate)!
        let timeline = Timeline(
            entries: [entry],
            policy: .after(entryDate)
        )
        completion(timeline)
    }
}

@main
struct KasaAppWidgets: WidgetBundle {

    @WidgetBundleBuilder
    var body: some Widget {
        KasaAppWidgetWithIntent()
        KasaAppWidgetStatic()
    }
}

struct KasaAppWidgetWithIntent: Widget {
    let kind: String = "KasaAppWidgetWithIntent"

    var body: some WidgetConfiguration {
        let provider = IntentProvider()

        return IntentConfiguration(
            kind: kind,
            intent: SelectDevicesIntent.self,
            provider: provider
        ) { entry in
            KasaAppWidgetEntryView(
                entry: entry,
                getURL: provider.config.render(link:),
                staticIntent: false
            )
        }
        .supportedFamilies([.systemExtraLarge, .systemLarge, .systemMedium, .systemSmall])
        .configurationDisplayName("Kasa 1")
        .description(WidgetFeature.Strings.descriptionWidget.string)

    }
}

struct KasaAppWidgetStatic: Widget {
    let kind: String = "KasaAppWidgetStatic"

    var body: some WidgetConfiguration {
        let provider = StaticProvider()

        return StaticConfiguration(
            kind: kind,
            provider: provider
        ) { entry in
            KasaAppWidgetEntryView(
                entry: entry,
                getURL: provider.config.render(link:),
                staticIntent: true
            )
        }
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline, .accessoryRectangular])
        .configurationDisplayName("Kasa 2")
        .description(WidgetFeature.Strings.descriptionWidget.string)

    }
}

#Preview(as: .systemMedium) {
    KasaAppWidgetWithIntent()
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
