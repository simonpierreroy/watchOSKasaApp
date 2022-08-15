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
import AppPackage

struct Provider: TimelineProvider {
    
    func newEntry(for context: Context,  completion: @escaping (DataDeviceEntry) -> ()) {
        let entry: DataDeviceEntry
        defer { completion(entry) }
        
        guard let cache = try? getCacheState(environment: .live) else {
            entry = DataDeviceEntry(date: Date(), userIsLogged: false, devices: [])
            return
        }
        
        if cache.user == nil {
            entry = DataDeviceEntry(date: Date(), userIsLogged: false, devices: [])
        } else {
            entry = DataDeviceEntry(date: Date(), userIsLogged: true, devices: cache.device)
        }
    }
    
    func placeholder(in context: Context) -> DataDeviceEntry {
        DataDeviceEntry.preview(10)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DataDeviceEntry) -> ()) {
        newEntry(for: context, completion: completion)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        newEntry(for: context) { entry in
            let currentDate = Date()
            let entryDate = Calendar.current.date(byAdding: .hour, value: 24, to: currentDate)!
            let timeline = Timeline(
                entries: [entry],
                policy: .after(entryDate)
            )
            completion(timeline)
        }
    }
}

struct DataDeviceEntry: TimelineEntry {
    static func preview(_ n: Int) -> DataDeviceEntry  {
        guard n > 0 else {
            return DataDeviceEntry.init(date: Date(), userIsLogged: true, devices: [])
        }
        return DataDeviceEntry(
            date: Date(),
            userIsLogged: true,
            devices: (1...n).map{ Device.init(
                id: .init(rawValue: "\($0)"),
                name: "Lampe du salaon \($0)",
                children: $0 == 3 ? [
                    .init(id: .init(rawValue: "child 1\($0)"), name: "child 1 of \($0)", state: false),
                    .init(id: .init(rawValue: "child 2\($0)"), name: "child 1 of \($0)", state: false)
                ] : [],
                state: false)
            }
        )
    }
    
    static let previewLogout = DataDeviceEntry(
        date: Date(),
        userIsLogged: false,
        devices: []
    )
    
    let date: Date
    let userIsLogged: Bool
    let devices: [Device]
    
}

struct KasaAppWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        WidgetView(logged: entry.userIsLogged, devices: entry.devices) { deviceLink in
            do {
                return try AppLink.URLRouter.live.print(AppLink.device(deviceLink))
            } catch {
                return URL(string: "urlWidgetDeepLinkIssue")!
            }
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
