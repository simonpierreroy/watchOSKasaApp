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
            Image(systemName: "lightbulb.slash.fill")
                .font(NoDevicesView.font(widgetFamily: widgetFamily))
            if NoDevicesView.showText(widgetFamily: widgetFamily) {
                Text(Strings.no_device.key, bundle: .module)
            }
        }
    }
}

struct DeviceView : View {
    
    @Environment(\.widgetFamily) var widgetFamily
    
    let device: Device
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
        Link(destination: getURL(.device(device.deepLink()))) {
            VStack {
                if device.children.count > 0 {
                    Image(systemName: "rectangle.3.group.fill").font(DeviceView.font(widgetFamily).0)
                    (Text(Strings.device_group.key, bundle: .module).font(DeviceView.font(widgetFamily).1)
                     +
                     Text(" (\(device.children.count))").font(DeviceView.font(widgetFamily).1))
                    .multilineTextAlignment(.center)
                } else {
                    Image(systemName: "light.max")
                        .font(DeviceView.font(widgetFamily).0)
                    Text("\(device.name)")
                        .multilineTextAlignment(.center)
                        .font(DeviceView.font(widgetFamily).1)
                }
                
            }.padding()
                .frame(maxWidth: .infinity,maxHeight: .infinity, alignment: .center)
                .frame(maxWidth: .infinity)
                .background(Color.button.opacity(0.2))
                .cornerRadius(16)
            
        }
    }
}

struct DeviceRowMaybe : View {
    let devices: (Device?,Device?)
    let getURL: (AppLink) -> URL
    
    var body: some View {
        HStack {
            DeviceViewMaybe(device: devices.0, getURL: getURL)
            DeviceViewMaybe(device: devices.1, getURL: getURL)
        }
    }
}

struct DeviceViewMaybe : View {
    let device: Device?
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
        Link(destination: getURL(.device(.closeAll))) {
            VStack {
                Image(systemName: "moon.zzz.fill")
                    .font(CloseAll.font(widgetFamily: widgetFamily))
                if CloseAll.showText(widgetFamily: widgetFamily) {
                    Text(Strings.close_all.key, bundle: .module)
                }
            }
        }
    }
}

struct StackList : View {
    @Environment(\.widgetFamily) var widgetFamily
    let devices: [Device]
    let getURL: (AppLink) -> URL
    
    var body: some View {
        if  devices.count > 0 {
            VStack {
                switch widgetFamily {
                case .systemSmall, .accessoryCircular, .accessoryInline, .accessoryRectangular:
                    CloseAll(
                        getURL: getURL,
                        toltalNumberDevices: devices.count
                    ).widgetURL(getURL(.device(.closeAll)))
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
            NoDevicesView()
        }
    }
}

#if DEBUG
struct DeviceView_Preview: PreviewProvider {
    static let previewDevices = (1...10)
        .map { i in Device.init(id: "\(i)", name: "Preview no \(i)", state: false) }
    static var previews: some View {
        Group {
            StackList(devices: DeviceView_Preview.previewDevices, getURL: { _ in return .mock })
                .previewDisplayName("StackList")
        }
    }
}
#endif

