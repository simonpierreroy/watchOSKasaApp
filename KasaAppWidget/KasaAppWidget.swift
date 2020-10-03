//
//  KasaAppWidget.swift
//  KasaAppWidget
//
//  Created by Simon-Pierre Roy on 10/3/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import WidgetKit
import SwiftUI
import UserFeature
import DeviceFeature
import UserClientLive
import DeviceClientLive
import DeviceClient
import UserClient
import KasaCore
import Combine

struct Provider: TimelineProvider {
    
    static var entryLoading: AnyCancellable? = nil
    
    func newEntry(for context: Context,  completion: @escaping (DataDeviceEntry) -> ()) {
        Provider.entryLoading = UserEnvironment
            .liveLoadUser
            .mapError(absurd)
            .zip(DevicesEnvironment.liveLoadCache) { (user: User?, devices: [Device]) -> DataDeviceEntry in
                if user == nil {
                    return DataDeviceEntry(date: Date(), userIsLogged: false, devices: [])
                } else {
                    return DataDeviceEntry(date: Date(), userIsLogged: true, devices: devices)
                }
            }.receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
            .sink { (comp) in
                print(comp)
            } receiveValue: { (entry) in
                completion(entry)
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
            devices: (1...n).map{ Device.init(id: .init(rawValue: "\($0)"), name: "Lampe du salaon \($0)") }
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
    @Environment(\.widgetFamily) var widgetFamily
    
    func grid(_ family: WidgetFamily ) ->  [GridItem] {
        switch family {
        case .systemLarge:
            return [GridItem(.flexible()), GridItem(.flexible())]
        case .systemMedium:
            return [GridItem(.flexible()), GridItem(.flexible())]
        case .systemSmall:
            return [GridItem(.flexible())]
        @unknown default:
            return [GridItem(.flexible())]
        }
    }
    
    func box(_ family: WidgetFamily) ->  CGSize {
        switch family {
        case .systemLarge:
            return CGSize(width: 150, height: 110)
        case .systemMedium:
            return CGSize(width: 150, height: 70)
        case .systemSmall:
            return CGSize(width: 135, height: 135)
        @unknown default:
            return CGSize(width: 125, height: 125)
        }
    }
     
    func data(_ family: WidgetFamily, _ devices: [Device]) ->  ArraySlice<Device>{
        guard devices.count > 0 else { return [] }
        
        let maxSize: Int
        switch family {
        case .systemLarge:
            maxSize = 6
        case .systemMedium:
            maxSize = 4
        case .systemSmall:
            maxSize = 1
        @unknown default:
            maxSize = 1
        }
        
        let size = min(devices.count, maxSize)
        return devices[0..<size]
    }
    
    func deviceSize(_ family: WidgetFamily) ->  (Font, Font){
        
        switch family {
        case .systemLarge:
            return (.title, .body)
        case .systemMedium:
            return (.title, .caption)
        case .systemSmall:
            return (.title, .body)
        @unknown default:
            return (.title, .body)
        }
    }
    
    var body: some View {
        VStack {
            if entry.userIsLogged {
                if  entry.devices.count > 0 {
                    LazyVGrid(columns: grid(self.widgetFamily)){
                        ForEach(
                            data(self.widgetFamily, self.entry.devices)
                        ) { device in
                            VStack {
                                Image(systemName: "light.max")
                                    .font(deviceSize(self.widgetFamily).0)
                                Text("\(device.name)")
                                    .multilineTextAlignment(.center)
                                    .font(deviceSize(self.widgetFamily).1)
                            }.padding()
                            .frame(
                                width: box(self.widgetFamily).width,
                                height: box(self.widgetFamily).height,
                                alignment: .center)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(16)
                        }
                    }.padding()
                } else {
                    VStack {
                        Image(systemName: "lightbulb.slash.fill")
                            .padding()
                            .font(.largeTitle)
                        Text(.no_device)
                    }
                }
                
            } else {
                VStack {
                    Image(systemName: "keyboard")
                        .font(.largeTitle)
                        .padding()
                    Text(.not_logged)
                }
            }
        }.frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: .infinity)
        .background(ContainerRelativeShape().fill(
            LinearGradient(
                gradient: Gradient(
                    colors:
                        [
                            Color.blue.opacity(0.8),
                            Color.blue
                        ]),
                startPoint: .top,
                endPoint: .bottom)
        ))
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
        .description("This is an example widget.")
        
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
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        KasaAppWidgetEntryView(entry: DataDeviceEntry.preview(10))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
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
