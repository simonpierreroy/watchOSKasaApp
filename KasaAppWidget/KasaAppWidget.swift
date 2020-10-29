//
//  KasaAppWidget.swift
//  KasaAppWidget
//
//  Created by Simon-Pierre Roy on 10/3/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import WidgetKit
import SwiftUI
import UserClient
import DeviceClient
import KasaCore
import Combine
import ComposableArchitecture

struct Provider: TimelineProvider {
    
    static var cancels: Set<AnyCancellable> = Set()
    
    func newEntry(for context: Context,  completion: @escaping (DataDeviceEntry) -> ()) {
        var cancel: AnyCancellable? = nil
        cancel = getCacheState(environment: .liveEnv)
            .sink { _ in Provider.cancels.remove(cancel!) }
                receiveValue:  { state in
                    let entry: DataDeviceEntry
                    if state.user == nil {
                        entry = DataDeviceEntry(date: Date(), userIsLogged: false, devices: [])
                    } else {
                        entry = DataDeviceEntry(date: Date(), userIsLogged: true, devices: state.device)
                    }
                    completion(entry)
                }
        Provider.cancels.insert(cancel!)
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
    
    var body: some View {
        VStack {
            if entry.userIsLogged {
                StackList(devices: entry.devices)
            } else {
                LogoutView()
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BackgroundWidget())
    }
}

struct StackList : View {
    @Environment(\.widgetFamily) var widgetFamily
    let devices: [Device]
    
    var body: some View {
        if  devices.count > 0 {
            VStack {
                switch widgetFamily {
                case .systemSmall:
                    DeviceViewMaybe(device: devices[safeIndex: 0])
                        .widgetURL(devices[safeIndex: 0]?.deepLink().getURL())
                case .systemMedium :
                    VStack{
                        DeviceRowMaybe(devices: (devices[safeIndex: 0], devices[safeIndex: 1]))
                        DeviceRowMaybe(devices: (devices[safeIndex: 2], devices[safeIndex: 3]))
                    }
                case .systemLarge:
                    VStack{
                        DeviceRowMaybe(devices: (devices[safeIndex: 0], devices[safeIndex: 1]))
                        DeviceRowMaybe(devices: (devices[safeIndex: 2], devices[safeIndex: 3]))
                        DeviceRowMaybe(devices: (devices[safeIndex: 4], devices[safeIndex: 5]))
                    }
                @unknown default:
                    EmptyView()
                }
            }.padding()
            
        } else {
            NoDevicesView()
        }
    }
}


struct DeviceRowMaybe : View {
    
    let devices: (Device?,Device?)
    
    var body: some View {
        HStack {
            DeviceViewMaybe(device: devices.0)
            DeviceViewMaybe(device: devices.1)
        }
    }
}

struct DeviceViewMaybe : View {
    
    let device: Device?
    
    var body: some View {
        if let device = device {
            DeviceView(device: device)
        } else {
            EmptyView()
        }
    }
}

struct DeviceView : View {
    
    @Environment(\.widgetFamily) var widgetFamily
    
    let device: Device
    
    func fontDevice(_ family: WidgetFamily) ->  (Font, Font){
        
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
        Link(destination: device.deepLink().getURL()) {
            VStack {
                Image(systemName: "light.max")
                    .font(fontDevice(widgetFamily).0)
                Text("\(device.name)")
                    .multilineTextAlignment(.center)
                    .font(fontDevice(widgetFamily).1)
            }.padding()
            .frame(maxWidth: .infinity,maxHeight: .infinity, alignment: .center)
            .frame(maxWidth: .infinity)
            .background(Color.button.opacity(0.2))
            .cornerRadius(16)
            
        }
    }
}

struct NoDevicesView: View {
    var body: some View {
        VStack {
            Image(systemName: "lightbulb.slash.fill")
                .padding()
                .font(.largeTitle)
            Text(.no_device)
        }
    }
}

struct LogoutView: View {
    var body: some View {
        ZStack {
            StackList(devices: DataDeviceEntry.preview(10).devices)
                .blur(radius: 4.0)
            VStack {
                Image(systemName: "keyboard")
                    .font(.largeTitle)
                    .padding()
                Text(.not_logged)
            }
        }
    }
}

struct BackgroundWidget: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ContainerRelativeShape().fill(
            LinearGradient(
                gradient: Gradient(
                    colors: [.backgroudStart, .backgroudEnd]
                ),
                startPoint: .top,
                endPoint: .bottom
            )
        )
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
        .description(.description_widget)
        
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
