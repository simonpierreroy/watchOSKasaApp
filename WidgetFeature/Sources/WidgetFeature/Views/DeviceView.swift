//
//  SwiftUIView.swift
//
//
//  Created by Simon-Pierre Roy on 2/6/21.
//

import AppIntents
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
    let mode: WidgetEntryMode

    static func showText(for widgetFamily: WidgetFamily) -> Bool {
        switch widgetFamily {
        case .accessoryInline, .systemMedium, .systemSmall,
            .systemLarge, .systemExtraLarge, .accessoryRectangular:
            true
        case .accessoryCircular, .accessoryCorner: false
        @unknown default: false
        }
    }

    static func font(for widgetFamily: WidgetFamily) -> Font {
        switch widgetFamily {
        case .accessoryRectangular: .callout
        case .systemMedium, .systemSmall, .systemLarge,
            .systemExtraLarge, .accessoryInline, .accessoryCircular, .accessoryCorner:
            .largeTitle
        @unknown default: .largeTitle
        }
    }

    static func showWidgetText(for widgetFamily: WidgetFamily) -> Bool {
        switch widgetFamily {
        case .accessoryCorner: true
        case .accessoryInline, .systemMedium, .systemSmall,
            .systemLarge, .systemExtraLarge, .accessoryRectangular, .accessoryCircular:
            false
        @unknown default: false
        }
    }

    static func imageName(for mode: WidgetEntryMode) -> String {
        switch mode {
        case .selectableMultiDevices: "square.and.pencil.circle"
        case .turnOffAllDevices: "lightbulb.slash.fill"
        }
    }

    static func text(for mode: WidgetEntryMode) -> LocalizedStringKey {
        switch mode {
        case .selectableMultiDevices: Strings.noDeviceSelected.key
        case .turnOffAllDevices: Strings.noDevice.key
        }
    }

    var body: some View {
        VStack {
            Image(systemName: NoDevicesView.imageName(for: mode))
                .font(NoDevicesView.font(for: widgetFamily))
                .widgetLabelOptional(active: Self.showWidgetText(for: widgetFamily)) {
                    Text(NoDevicesView.text(for: mode), bundle: .module)
                        .widgetAccentable(true)
                }
            if NoDevicesView.showText(for: widgetFamily) {
                Text(NoDevicesView.text(for: mode), bundle: .module)
            }
        }
    }
}

#if os(iOS)
struct DeviceView<I: AppIntent>: View {

    @Environment(\.widgetFamily) var widgetFamily

    let device: FlattenDevice
    let newIntent: (FlattenDevice) -> I

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
        Button(intent: newIntent(self.device)) {
            VStack {
                Image(systemName: "light.max")
                    .font(DeviceView.font(for: widgetFamily).0)
                Text("\(device.displayName)")
                    .multilineTextAlignment(.center)
                    .font(DeviceView.font(for: widgetFamily).1)

            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(Color.button.opacity(0.2))
            .clipShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain).invalidatableContent()
    }
}

struct DeviceRowMaybe<I: AppIntent>: View {
    let devices: (FlattenDevice?, FlattenDevice?)
    let newIntent: (FlattenDevice?) -> I

    var body: some View {
        HStack {
            DeviceViewMaybe(device: devices.0, newIntent: newIntent)
            DeviceViewMaybe(device: devices.1, newIntent: newIntent)
        }
    }
}

struct DeviceViewMaybe<I: AppIntent>: View {
    let device: FlattenDevice?
    let newIntent: (FlattenDevice?) -> I

    var body: some View {
        if let device = device {
            DeviceView(device: device, newIntent: newIntent)
        } else {
            EmptyView()
        }
    }
}
#endif

struct TurnOffView<I: AppIntent>: View {
    let newIntent: () -> I
    let getURL: (AppLink) -> URL
    let toltalNumberDevices: Int

    @Environment(\.widgetFamily) var widgetFamily

    static func showText(for widgetFamily: WidgetFamily) -> Bool {
        switch widgetFamily {
        case .accessoryInline, .systemMedium, .systemSmall,
            .systemLarge, .systemExtraLarge, .accessoryRectangular:
            true
        case .accessoryCircular, .accessoryCorner: false
        @unknown default: false
        }
    }

    static func showWidgetText(for widgetFamily: WidgetFamily) -> Bool {
        switch widgetFamily {
        case .accessoryCorner: true
        case .accessoryInline, .systemMedium, .systemSmall,
            .systemLarge, .systemExtraLarge, .accessoryRectangular, .accessoryCircular:
            false
        @unknown default: false
        }
    }

    static func font(for widgetFamily: WidgetFamily) -> Font {
        switch widgetFamily {
        case .accessoryRectangular: .callout
        case .systemMedium, .systemSmall, .systemLarge,
            .systemExtraLarge, .accessoryInline, .accessoryCircular, .accessoryCorner:
            .largeTitle
        @unknown default: .largeTitle
        }
    }

    var body: some View {
        Button(intent: newIntent()) {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .buttonStyle(.plain).invalidatableContent()
        .widgetURL(getURL(.devices(.turnOffAllDevices)))
        //  vs Link(destination: getURL(.devices(.turnOffAllDevices)))
    }
}

struct StackList<I: AppIntent>: View {
    @Environment(\.widgetFamily) var widgetFamily
    let devices: [FlattenDevice]
    let newIntent: (FlattenDevice?) -> I
    let getURL: (AppLink) -> URL
    let mode: WidgetEntryMode

    var body: some View {
        if devices.count > 0 {
            VStack {
                switch (widgetFamily, mode) {
                case (_, .turnOffAllDevices):
                    TurnOffView(
                        newIntent: { newIntent(nil) },
                        getURL: getURL,
                        toltalNumberDevices: devices.count
                    )
                #if os(iOS)
                case (.systemSmall, .selectableMultiDevices), (.accessoryCircular, .selectableMultiDevices),
                    (.accessoryInline, .selectableMultiDevices), (.accessoryRectangular, .selectableMultiDevices),
                    (.accessoryCorner, .selectableMultiDevices):
                    DeviceViewMaybe(device: devices[safeIndex: 0], newIntent: newIntent)

                case (.systemMedium, .selectableMultiDevices):
                    VStack {
                        DeviceRowMaybe(devices: (devices[safeIndex: 0], devices[safeIndex: 1]), newIntent: newIntent)
                        DeviceRowMaybe(devices: (devices[safeIndex: 2], devices[safeIndex: 3]), newIntent: newIntent)
                    }
                case (.systemLarge, .selectableMultiDevices):
                    VStack {
                        DeviceRowMaybe(devices: (devices[safeIndex: 0], devices[safeIndex: 1]), newIntent: newIntent)
                        DeviceRowMaybe(devices: (devices[safeIndex: 2], devices[safeIndex: 3]), newIntent: newIntent)
                        DeviceRowMaybe(devices: (devices[safeIndex: 4], devices[safeIndex: 5]), newIntent: newIntent)
                    }
                case (.systemExtraLarge, .selectableMultiDevices):
                    VStack {
                        DeviceRowMaybe(devices: (devices[safeIndex: 0], devices[safeIndex: 1]), newIntent: newIntent)
                        DeviceRowMaybe(devices: (devices[safeIndex: 2], devices[safeIndex: 3]), newIntent: newIntent)
                        DeviceRowMaybe(devices: (devices[safeIndex: 4], devices[safeIndex: 5]), newIntent: newIntent)
                        DeviceRowMaybe(devices: (devices[safeIndex: 6], devices[safeIndex: 7]), newIntent: newIntent)
                    }
                #endif
                #if os(watchOS)
                case (.accessoryCircular, .selectableMultiDevices), (.accessoryCorner, .selectableMultiDevices),
                    (.accessoryInline, .selectableMultiDevices), (.accessoryRectangular, .selectableMultiDevices):
                    Text("ERROR")
                #endif
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            NoDevicesView(mode: mode)
        }
    }
}

#if DEBUG

let previewDevices = (1...10)
    .map { i in Device.init(id: "\(i)", name: "Preview no \(i)", details: .status(relay: false, info: .mock)) }
#Preview("StackList") {
    StackList(
        devices: previewDevices.flatten(),
        newIntent: { _ in return EmptyIntent() },
        getURL: { _ in return .mock },
        mode: .selectableMultiDevices
    )
}

#Preview("StackList Static") {
    StackList(
        devices: previewDevices.flatten(),
        newIntent: { _ in return EmptyIntent() },
        getURL: { _ in return .mock },
        mode: .turnOffAllDevices
    )
}
#endif
