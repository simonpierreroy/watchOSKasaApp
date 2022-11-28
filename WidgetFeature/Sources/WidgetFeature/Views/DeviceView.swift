//
//  SwiftUIView.swift
//  
//
//  Created by Simon-Pierre Roy on 2/6/21.
//

import SwiftUI
import WidgetKit
import DeviceClient
import RoutingClient

struct NoDevicesView: View {
    
    @Environment(\.widgetFamily) var widgetFamily
    let staticIntent: Bool
    
    static func showText(widgetFamily: WidgetFamily) -> Bool {
        switch widgetFamily {
        case .accessoryInline, .systemMedium, .systemSmall,
                .systemLarge, .systemExtraLarge, .accessoryRectangular:
            return true
        case .accessoryCircular :
            return false
        @unknown default:
            return false
        }
    }
    
    static func font(widgetFamily: WidgetFamily) -> Font {
        switch widgetFamily {
        case .accessoryRectangular:
            return .callout
        case .systemMedium,.systemSmall,.systemLarge,
                .systemExtraLarge,.accessoryInline,.accessoryCircular:
            return .largeTitle
        @unknown default:
            return .largeTitle
        }
    }
    
    var body: some View {
        VStack {
            Image(systemName:
                    staticIntent ? "lightbulb.slash.fill" : "square.and.pencil.circle"
            ).font(NoDevicesView.font(widgetFamily: widgetFamily))
            if NoDevicesView.showText(widgetFamily: widgetFamily) {
                Text(
                    staticIntent ? Strings.no_device.key  :  Strings.no_device_selected.key,
                    bundle: .module
                )
            }
        }
    }
}

struct DeviceView : View {
    
    @Environment(\.widgetFamily) var widgetFamily
    
    let device: FlattenDevice
    let getURL: (AppLink) -> URL
    
    static func font(_ family: WidgetFamily) ->  (Font, Font){
        
        switch family {
        case .systemLarge:
            return (.title, .body)
        case .systemMedium:
            return (.caption, .caption)
        case .systemSmall:
            return (.title, .body)
        case .systemExtraLarge:
            return (.title, .body)
        case .accessoryRectangular, .accessoryInline, .accessoryCircular:
            return (.title, .body)
        @unknown default:
            return (.title, .body)
        }
    }
    
    var body: some View {
        Link(destination: getURL(getLink())) {
            VStack {
                Image(systemName: "light.max")
                    .font(DeviceView.font(widgetFamily).0)
                Text("\(device.child?.name ?? device.device.name )")
                    .multilineTextAlignment(.center)
                    .font(DeviceView.font(widgetFamily).1)
                
            }.padding()
                .frame(maxWidth: .infinity,maxHeight: .infinity, alignment: .center)
                .frame(maxWidth: .infinity)
                .background(Color.button.opacity(0.2))
                .cornerRadius(16)
            
        }.widgetURL(getURL(getLink())) // widgetURL when is small view
    }
    
    func getLink() -> AppLink {
        if let child = device.child {
            return .devices(.device(device.device.id, .child(child.id,.toggle)))
        } else {
            return .devices(.device(device.device.id, .toggle))
        }
    }
}

struct DeviceRowMaybe : View {
    let devices: (FlattenDevice?,FlattenDevice?)
    let getURL: (AppLink) -> URL
    
    var body: some View {
        HStack {
            DeviceViewMaybe(device: devices.0, getURL: getURL)
            DeviceViewMaybe(device: devices.1, getURL: getURL)
        }
    }
}

struct DeviceViewMaybe : View {
    let device: FlattenDevice?
    let getURL: (AppLink) -> URL
    
    var body: some View {
        if let device = device {
            DeviceView(device: device, getURL: getURL)
        } else {
            EmptyView()
        }
    }
}

struct CloseAll : View {
    let getURL: (AppLink) -> URL
    let toltalNumberDevices: Int
    @Environment(\.widgetFamily) var widgetFamily
    
    
    static func showText(widgetFamily: WidgetFamily) -> Bool {
        switch widgetFamily {
        case .accessoryInline, .systemMedium, .systemSmall,
                .systemLarge, .systemExtraLarge, .accessoryRectangular:
            return true
        case .accessoryCircular :
            return false
        @unknown default:
            return false
        }
    }
    
    static func font(widgetFamily: WidgetFamily) -> Font {
        switch widgetFamily {
        case .accessoryRectangular:
            return .callout
        case .systemMedium,.systemSmall,.systemLarge,
                .systemExtraLarge,.accessoryInline,.accessoryCircular:
            return .largeTitle
        @unknown default:
            return .largeTitle
        }
    }
    
    var body: some View {
        Link(destination: getURL(.devices(.closeAll))) {
            VStack {
                Image(systemName: "moon.zzz.fill")
                    .font(CloseAll.font(widgetFamily: widgetFamily))
                if CloseAll.showText(widgetFamily: widgetFamily) {
                    Text(Strings.close_all.key, bundle: .module)
                }
            }
        }.widgetURL(getURL(.devices(.closeAll))) // for small views
    }
}

struct StackList : View {
    @Environment(\.widgetFamily) var widgetFamily
    let devices: [FlattenDevice]
    let getURL: (AppLink) -> URL
    let staticIntent: Bool
    
    var body: some View {
        if  devices.count > 0 {
            VStack {
                switch widgetFamily {
                case .systemSmall, .accessoryCircular, .accessoryInline, .accessoryRectangular:
                    if staticIntent {
                        CloseAll(
                            getURL: getURL,
                            toltalNumberDevices: devices.count
                        )
                    } else {
                        DeviceViewMaybe(device: devices[safeIndex: 0], getURL: getURL)
                    }
                case .systemMedium :
                    VStack{
                        DeviceRowMaybe(devices: (devices[safeIndex: 0], devices[safeIndex: 1]), getURL: getURL)
                        DeviceRowMaybe(devices: (devices[safeIndex: 2], devices[safeIndex: 3]), getURL: getURL)
                    }
                case .systemLarge:
                    VStack{
                        DeviceRowMaybe(devices: (devices[safeIndex: 0], devices[safeIndex: 1]), getURL: getURL)
                        DeviceRowMaybe(devices: (devices[safeIndex: 2], devices[safeIndex: 3]), getURL: getURL)
                        DeviceRowMaybe(devices: (devices[safeIndex: 4], devices[safeIndex: 5]), getURL: getURL)
                    }
                case .systemExtraLarge:
                    VStack{
                        DeviceRowMaybe(devices: (devices[safeIndex: 0], devices[safeIndex: 1]), getURL: getURL)
                        DeviceRowMaybe(devices: (devices[safeIndex: 2], devices[safeIndex: 3]), getURL: getURL)
                        DeviceRowMaybe(devices: (devices[safeIndex: 4], devices[safeIndex: 5]), getURL: getURL)
                        DeviceRowMaybe(devices: (devices[safeIndex: 6], devices[safeIndex: 7]), getURL: getURL)
                    }
                @unknown default:
                    EmptyView()
                }
            }.padding()
            
        } else {
            NoDevicesView(staticIntent: staticIntent)
        }
    }
}

#if DEBUG
struct DeviceView_Preview: PreviewProvider {
    static let previewDevices = (1...10)
        .map { i in Device.init(id: "\(i)", name: "Preview no \(i)", state: false) }
    static var previews: some View {
        Group {
            StackList(devices: DeviceView_Preview.previewDevices.flatten(), getURL: { _ in return .mock }, staticIntent: false)
                .previewDisplayName("StackList")
            StackList(devices: DeviceView_Preview.previewDevices.flatten(), getURL: { _ in return .mock }, staticIntent: true)
                .previewDisplayName("StackList Static")
        }
    }
}
#endif

