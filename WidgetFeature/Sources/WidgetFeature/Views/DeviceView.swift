//
//  SwiftUIView.swift
//
//
//  Created by Simon-Pierre Roy on 2/6/21.
//

import DeviceClient
import RoutingClient
import SwiftUI
import WidgetKit

extension View {
    @ViewBuilder
    func widgetLabelOptional<Label: View>(active: Bool, @ViewBuilder label: () -> Label) -> some View {
        if active {
            self.widgetLabel(label: label)
        } else {
            self
        }
    }
}

struct NoDevicesView: View {

    @Environment(\.widgetFamily) var widgetFamily
    let staticIntent: Bool

    static func showText(for widgetFamily: WidgetFamily) -> Bool {
        switch widgetFamily {
        case .accessoryInline, .systemMedium, .systemSmall,
            .systemLarge, .systemExtraLarge, .accessoryRectangular:
            return true
        case .accessoryCircular, .accessoryCorner:
            return false
        @unknown default:
            return false
        }
    }

    static func font(for widgetFamily: WidgetFamily) -> Font {
        switch widgetFamily {
        case .accessoryRectangular:
            return .callout
        case .systemMedium, .systemSmall, .systemLarge,
            .systemExtraLarge, .accessoryInline, .accessoryCircular, .accessoryCorner:
            return .largeTitle
        @unknown default:
            return .largeTitle
        }
    }

    static func showWidgetText(for widgetFamily: WidgetFamily) -> Bool {
        switch widgetFamily {
        case .accessoryCorner:
            return true
        case .accessoryInline, .systemMedium, .systemSmall,
            .systemLarge, .systemExtraLarge, .accessoryRectangular, .accessoryCircular:
            return false
        @unknown default:
            return false
        }
    }

    var body: some View {
        VStack {
            Image(
                systemName:
                    staticIntent ? "lightbulb.slash.fill" : "square.and.pencil.circle"
            )
            .font(NoDevicesView.font(for: widgetFamily))
            .widgetLabelOptional(active: TurnOffView.showWidgetText(for: widgetFamily)) {
                Text(
                    staticIntent ? Strings.noDevice.key : Strings.noDeviceSelected.key,
                    bundle: .module
                )
                .widgetAccentable(true)
            }
            if NoDevicesView.showText(for: widgetFamily) {
                Text(
                    staticIntent ? Strings.noDevice.key : Strings.noDeviceSelected.key,
                    bundle: .module
                )
            }
        }
    }
}

#if os(iOS)
struct DeviceView: View {

    @Environment(\.widgetFamily) var widgetFamily

    let device: FlattenDevice
    let getURL: (AppLink) -> URL

    static func font(for family: WidgetFamily) -> (Font, Font) {

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
                    .font(DeviceView.font(for: widgetFamily).0)
                Text("\(device.child?.name ?? device.device.name )")
                    .multilineTextAlignment(.center)
                    .font(DeviceView.font(for: widgetFamily).1)

            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .frame(maxWidth: .infinity)
            .background(Color.button.opacity(0.2))
            .clipShape(.rect(cornerRadius: 16))
        }
        .widgetURL(getURL(getLink()))  // widgetURL when is small view
    }

    func getLink() -> AppLink {
        guard let child = device.child else {
            return .devices(.device(device.device.id, .toggle))
        }
        return .devices(.device(device.device.id, .child(child.id, .toggle)))
    }
}

struct DeviceRowMaybe: View {
    let devices: (FlattenDevice?, FlattenDevice?)
    let getURL: (AppLink) -> URL

    var body: some View {
        HStack {
            DeviceViewMaybe(device: devices.0, getURL: getURL)
            DeviceViewMaybe(device: devices.1, getURL: getURL)
        }
    }
}

struct DeviceViewMaybe: View {
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
#endif

struct TurnOffView: View {
    let getURL: (AppLink) -> URL
    let toltalNumberDevices: Int
    @Environment(\.widgetFamily) var widgetFamily

    static func showText(for widgetFamily: WidgetFamily) -> Bool {
        switch widgetFamily {
        case .accessoryInline, .systemMedium, .systemSmall,
            .systemLarge, .systemExtraLarge, .accessoryRectangular:
            return true
        case .accessoryCircular, .accessoryCorner:
            return false
        @unknown default:
            return false
        }
    }

    static func showWidgetText(for widgetFamily: WidgetFamily) -> Bool {
        switch widgetFamily {
        case .accessoryCorner:
            return true
        case .accessoryInline, .systemMedium, .systemSmall,
            .systemLarge, .systemExtraLarge, .accessoryRectangular, .accessoryCircular:
            return false
        @unknown default:
            return false
        }
    }

    static func font(for widgetFamily: WidgetFamily) -> Font {
        switch widgetFamily {
        case .accessoryRectangular:
            return .callout
        case .systemMedium, .systemSmall, .systemLarge,
            .systemExtraLarge, .accessoryInline, .accessoryCircular, .accessoryCorner:
            return .largeTitle
        @unknown default:
            return .largeTitle
        }
    }

    var body: some View {
        Link(destination: getURL(.devices(.turnOffAllDevices))) {
            VStack {
                Image(systemName: "moon.zzz.fill")
                    .font(TurnOffView.font(for: widgetFamily))
                    .widgetLabelOptional(active: TurnOffView.showWidgetText(for: widgetFamily)) {
                        Text(Strings.turnOff.key, bundle: .module).widgetAccentable(true)

                    }
                if TurnOffView.showText(for: widgetFamily) {
                    Text(Strings.turnOff.key, bundle: .module)
                }
            }
            .widgetAccentable(widgetFamily == .accessoryRectangular)
        }
        .widgetURL(getURL(.devices(.turnOffAllDevices)))  // for small views
    }
}

struct StackList: View {
    @Environment(\.widgetFamily) var widgetFamily
    let devices: [FlattenDevice]
    let getURL: (AppLink) -> URL
    let staticIntent: Bool

    var body: some View {
        if devices.count > 0 {
            VStack {
                switch widgetFamily {
                case .systemSmall, .accessoryCircular, .accessoryInline, .accessoryRectangular, .accessoryCorner:
                    if staticIntent {
                        TurnOffView(
                            getURL: getURL,
                            toltalNumberDevices: devices.count
                        )
                    } else {
                        #if os(iOS)
                        DeviceViewMaybe(device: devices[safeIndex: 0], getURL: getURL)
                        #endif
                    }
                #if os(iOS)
                case .systemMedium:
                    VStack {
                        DeviceRowMaybe(devices: (devices[safeIndex: 0], devices[safeIndex: 1]), getURL: getURL)
                        DeviceRowMaybe(devices: (devices[safeIndex: 2], devices[safeIndex: 3]), getURL: getURL)
                    }
                case .systemLarge:
                    VStack {
                        DeviceRowMaybe(devices: (devices[safeIndex: 0], devices[safeIndex: 1]), getURL: getURL)
                        DeviceRowMaybe(devices: (devices[safeIndex: 2], devices[safeIndex: 3]), getURL: getURL)
                        DeviceRowMaybe(devices: (devices[safeIndex: 4], devices[safeIndex: 5]), getURL: getURL)
                    }
                case .systemExtraLarge:
                    VStack {
                        DeviceRowMaybe(devices: (devices[safeIndex: 0], devices[safeIndex: 1]), getURL: getURL)
                        DeviceRowMaybe(devices: (devices[safeIndex: 2], devices[safeIndex: 3]), getURL: getURL)
                        DeviceRowMaybe(devices: (devices[safeIndex: 4], devices[safeIndex: 5]), getURL: getURL)
                        DeviceRowMaybe(devices: (devices[safeIndex: 6], devices[safeIndex: 7]), getURL: getURL)
                    }
                #endif
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            NoDevicesView(staticIntent: staticIntent)
        }
    }
}

#if DEBUG
let previewDevices = (1...10)
    .map { i in Device.init(id: "\(i)", name: "Preview no \(i)", details: .status(relay: false, info: .mock)) }
#Preview("StackList") {
    StackList(
        devices: previewDevices.flatten(),
        getURL: { _ in return .mock },
        staticIntent: false
    )
}

#Preview("StackList Static") {
    StackList(
        devices: previewDevices.flatten(),
        getURL: { _ in return .mock },
        staticIntent: true
    )
}
#endif
