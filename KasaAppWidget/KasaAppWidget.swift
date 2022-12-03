//
//  KasaAppWidget.swift
//  KasaAppWidget
//
//  Created by Simon-Pierre Roy on 10/3/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Combine
import Dependencies
import DeviceClient
import RoutingClient
import RoutingClientLive
import SwiftUI
import WidgetClient
import WidgetClientLive
import WidgetFeature
import WidgetKit

struct ProviderConfig {

    @Dependency(\.userCache.loadBlocking) var loadUser
    @Dependency(\.devicesCache.loadBlocking) var loadDevices
    @Dependency(\.urlRouter.print) var getURL

    func render(link: AppLink) -> URL {
        do {
            return try getURL(link)
        } catch {
            return URL(string: "urlWidgetDeepLinkIssue")!
        }
    }

}

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

struct KasaAppWidgetEntryView: View {
    var entry: DataDeviceEntry
    let getURL: (AppLink) -> URL
    let staticIntent: Bool

    var body: some View {
        WidgetView(
            logged: entry.userIsLogged,
            devices: entry.devices,
            getURL: getURL,
            staticIntent: staticIntent
        )
    }
}

@main
struct KasaAppWidgets: WidgetBundle {

    @WidgetBundleBuilder
    var body: some Widget {
        KasaAppWidgetWithItent()
        KasaAppWidgetStatic()
    }
}

struct KasaAppWidgetWithItent: Widget {
    let kind: String = "KasaAppWidgetWithItent"

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
        .description(WidgetFeature.Strings.description_widget.string)

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
        .description(WidgetFeature.Strings.description_widget.string)

    }
}

struct KasaAppWidget_Previews: PreviewProvider {
    static var previews: some View {
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(10),
            getURL: ProviderConfig().render(link:),
            staticIntent: false
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        .environment(\.colorScheme, .dark)
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(10),
            getURL: ProviderConfig().render(link:),
            staticIntent: true
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        .environment(\.colorScheme, .dark)
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(0),
            getURL: ProviderConfig().render(link:),
            staticIntent: false
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(10),
            getURL: ProviderConfig().render(link:),
            staticIntent: false
        )
        .previewContext(WidgetPreviewContext(family: .systemMedium))
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(3),
            getURL: ProviderConfig().render(link:),
            staticIntent: false
        )
        .previewContext(WidgetPreviewContext(family: .systemMedium))
        .environment(\.colorScheme, .dark)
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(1),
            getURL: ProviderConfig().render(link:),
            staticIntent: false
        )
        .previewContext(WidgetPreviewContext(family: .systemMedium))
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(0),
            getURL: ProviderConfig().render(link:),
            staticIntent: false
        )
        .previewContext(WidgetPreviewContext(family: .systemMedium))
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(10),
            getURL: ProviderConfig().render(link:),
            staticIntent: false
        )
        .previewContext(WidgetPreviewContext(family: .systemLarge))
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(3),
            getURL: ProviderConfig().render(link:),
            staticIntent: false
        )
        .previewContext(WidgetPreviewContext(family: .systemLarge))
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.previewLogout,
            getURL: ProviderConfig().render(link:),
            staticIntent: false
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
