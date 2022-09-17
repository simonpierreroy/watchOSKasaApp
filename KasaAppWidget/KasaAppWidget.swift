//
//  KasaAppWidget.swift
//  KasaAppWidget
//
//  Created by Simon-Pierre Roy on 10/3/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import WidgetKit
import SwiftUI
import Combine

import WidgetFeature
import WidgetClientLive
import WidgetClient
import DeviceClient

extension DataDeviceEntry: TimelineEntry { }

struct Provider: TimelineProvider {
    
    func placeholder(in context: Context) -> DataDeviceEntry {
        .preview(10)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DataDeviceEntry) -> ()) {
        completion(newEntry(env: .live, for: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = newEntry(env: .live, for: context)
        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .hour, value: 24, to: currentDate)!
        let timeline = Timeline(
            entries: [entry],
            policy: .after(entryDate)
        )
        completion(timeline)
    }
}

struct KasaAppWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        WidgetView(logged: entry.userIsLogged, devices: entry.devices) { deviceLink in
            WidgetEnvironment.live.getURL(deviceLink)
        }
    }
}

@main
struct KasaAppWidget: Widget {
    let kind: String = "KasaAppWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            KasaAppWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.accessoryCircular,.accessoryInline,
                            .accessoryRectangular,.systemExtraLarge,
                            .systemLarge,.systemMedium,.systemSmall])
        .configurationDisplayName("Kasa")
        .description(WidgetFeature.Strings.description_widget.string)
        
    }
}

struct KasaAppWidget_Previews: PreviewProvider {
    static var previews: some View {
        KasaAppWidgetEntryView(entry: DataDeviceEntry.preview(10))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.colorScheme, .dark)
        KasaAppWidgetEntryView(entry: DataDeviceEntry.preview(0))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        KasaAppWidgetEntryView(entry: DataDeviceEntry.preview(10))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        KasaAppWidgetEntryView(entry: DataDeviceEntry.preview(3))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.colorScheme, .dark)
        KasaAppWidgetEntryView(entry: DataDeviceEntry.preview(1))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        KasaAppWidgetEntryView(entry: DataDeviceEntry.preview(0))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        KasaAppWidgetEntryView(entry: DataDeviceEntry.preview(10))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
        KasaAppWidgetEntryView(entry: DataDeviceEntry.preview(3))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
        KasaAppWidgetEntryView(entry: DataDeviceEntry.previewLogout)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        KasaAppWidgetEntryView(entry: DataDeviceEntry.previewLogout)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.colorScheme, .dark)
    }
}
