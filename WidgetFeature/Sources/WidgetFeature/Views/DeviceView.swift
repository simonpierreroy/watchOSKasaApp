//
//  SwiftUIView.swift
//  
//
//  Created by Simon-Pierre Roy on 2/6/21.
//

import SwiftUI
import WidgetKit
import DeviceClient

struct NoDevicesView: View {
    var body: some View {
        VStack {
            Image(systemName: "lightbulb.slash.fill")
                .padding()
                .font(.largeTitle)
            Text(Strings.no_device.key, bundle: .module)
        }
    }
}

struct DeviceView : View {
    
    @Environment(\.widgetFamily) var widgetFamily
    
    let device: Device
    
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
        @unknown default:
            return (.title, .body)
        }
    }
    
    var body: some View {
        Link(destination: device.deepLink().getURL()) {
            VStack {
                Image(systemName: "light.max")
                    .font(DeviceView.font(widgetFamily).0)
                Text("\(device.name)")
                    .multilineTextAlignment(.center)
                    .font(DeviceView.font(widgetFamily).1)
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
                case .systemExtraLarge:
                    VStack{
                        DeviceRowMaybe(devices: (devices[safeIndex: 0], devices[safeIndex: 1]))
                        DeviceRowMaybe(devices: (devices[safeIndex: 2], devices[safeIndex: 3]))
                        DeviceRowMaybe(devices: (devices[safeIndex: 4], devices[safeIndex: 5]))
                        DeviceRowMaybe(devices: (devices[safeIndex: 6], devices[safeIndex: 7]))
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
            StackList(devices: DeviceView_Preview.previewDevices)
                .previewDisplayName("StackList")
        }
    }
}
#endif

