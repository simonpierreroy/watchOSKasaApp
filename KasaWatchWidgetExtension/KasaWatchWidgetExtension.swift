//
//  KasaWatchWidgetExtension.swift
//  KasaWatchWidgetExtension
//
//  Created by Simon-Pierre Roy on 5/3/23.
//  Copyright © 2023 Simon. All rights reserved.
//

import Intents
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

@main
struct KasaWatchWidgetExtension: Widget {
    let kind: String = "KasaWatchWidgetExtensionStatic"

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
        .configurationDisplayName("Kasa")
        .description(WidgetFeature.Strings.descriptionWidget.string)

    }
}

struct KasaWatchWidgetExtension_Previews: PreviewProvider {
    static var previews: some View {
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(1),
            getURL: ProviderConfig().render(link:),
            staticIntent: true
        )
        .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.previewLogout,
            getURL: ProviderConfig().render(link:),
            staticIntent: true
        )
        .previewContext(WidgetPreviewContext(family: .accessoryCorner))
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.previewNoDevice,
            getURL: ProviderConfig().render(link:),
            staticIntent: true
        )
        .previewContext(WidgetPreviewContext(family: .accessoryInline))
    }
}
