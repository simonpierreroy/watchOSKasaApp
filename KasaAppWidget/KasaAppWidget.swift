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
import RoutingClientLive
import RoutingClient
import WidgetFeature
import WidgetClientLive
import WidgetClient
import DeviceClient
import Dependencies

extension DataDeviceEntry: TimelineEntry { }

struct Provider: TimelineProvider {
    
    @Dependency(\.userCache.loadBlocking) var loadUser
    @Dependency(\.devicesCache.loadBlocking) var loadDevices
    @Dependency(\.urlRouter.print) var getURL
    
    func placeholder(in context: Context) -> DataDeviceEntry {
        .preview(10)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DataDeviceEntry) -> ()) {
        completion(newEntry(
            cache: .init(loadDevices: loadDevices, loadUser: loadUser),
            for: context)
        )
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = newEntry(
            cache: .init(loadDevices: loadDevices, loadUser: loadUser),
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
    
    func render(link: AppLink) -> URL {
        do {
            return try getURL(link)
        } catch {
            return URL(string: "urlWidgetDeepLinkIssue")!
        }
    }
}

struct KasaAppWidgetEntryView : View {
    var entry: Provider.Entry
    let getURL: (AppLink) -> URL
    
    var body: some View {
        WidgetView(
            logged: entry.userIsLogged,
            devices: entry.devices,
            getURL: getURL
        )
    }
}

@main
struct KasaAppWidget: Widget {
    let kind: String = "KasaAppWidget"
    
    var body: some WidgetConfiguration {
        let provider = Provider()
        return StaticConfiguration(kind: kind, provider: provider) { entry in
            KasaAppWidgetEntryView(entry: entry, getURL: provider.render(link:))
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
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(10),
            getURL: Provider().render(link:)
        ).previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.colorScheme, .dark)
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(0),
            getURL: Provider().render(link:)
        ).previewContext(WidgetPreviewContext(family: .systemSmall))
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(10),
            getURL: Provider().render(link:)
        ).previewContext(WidgetPreviewContext(family: .systemMedium))
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(3),
            getURL: Provider().render(link:)
        ).previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.colorScheme, .dark)
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(1),
            getURL: Provider().render(link:)
        ).previewContext(WidgetPreviewContext(family: .systemMedium))
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(0),
            getURL: Provider().render(link:)
        ).previewContext(WidgetPreviewContext(family: .systemMedium))
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(10),
            getURL: Provider().render(link:)
        ).previewContext(WidgetPreviewContext(family: .systemLarge))
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.preview(3),
            getURL: Provider().render(link:)
        ).previewContext(WidgetPreviewContext(family: .systemLarge))
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.previewLogout,
            getURL: Provider().render(link:)
        ).previewContext(WidgetPreviewContext(family: .systemSmall))
        KasaAppWidgetEntryView(
            entry: DataDeviceEntry.previewLogout,
            getURL: Provider().render(link:)
        ).previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.colorScheme, .dark)
    }
}
