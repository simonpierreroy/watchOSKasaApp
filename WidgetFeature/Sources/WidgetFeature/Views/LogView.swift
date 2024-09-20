//
//  SwiftUIView.swift
//
//
//  Created by Simon-Pierre Roy on 2/6/21.
//

import BaseUI
import DeviceClient
import RoutingClient
import SwiftUI
import WidgetKit

struct LogoutView: View {
    static let logoutDevicesPreview = (1...10)
        .map { i in Device.init(id: "\(i)", name: "Here is device no \(i)", details: .status(relay: false, info: .mock))
        }
        .flatten()

    let getURL: (AppLink) -> URL
    let mode: WidgetEntryMode

    @Environment(\.widgetFamily) var widgetFamily

    static func showBackground(for widgetFamily: WidgetFamily) -> Bool {
        switch widgetFamily {
        case .accessoryInline, .accessoryRectangular, .accessoryCircular, .accessoryCorner: false
        case .systemMedium, .systemSmall, .systemLarge, .systemExtraLarge: true
        @unknown default: false
        }
    }

    static func showText(for widgetFamily: WidgetFamily) -> Bool {
        switch widgetFamily {
        case .accessoryCircular, .accessoryCorner: false
        case .systemMedium, .systemSmall, .systemLarge, .systemExtraLarge, .accessoryInline, .accessoryRectangular: true
        @unknown default: false
        }
    }

    static func imageFont(for widgetFamily: WidgetFamily) -> Font {
        switch widgetFamily {
        case .accessoryRectangular: .body
        case .systemMedium, .systemSmall, .systemLarge, .systemExtraLarge, .accessoryInline, .accessoryCircular,
            .accessoryCorner:
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

    var body: some View {
        ZStack {
            if LogoutView.showBackground(for: widgetFamily) {
                StackList(
                    devices: LogoutView.logoutDevicesPreview,
                    newIntent: { _ in return EmptyIntent() },
                    getURL: getURL,
                    mode: mode
                )
                .disabled(true).blur(radius: 4.0)
            }
            VStack {
                SharedSystemImages.notLogged()
                    .font(LogoutView.imageFont(for: widgetFamily))
                    .widgetLabelOptional(active: Self.showWidgetText(for: widgetFamily)) {
                        Text(Strings.notLogged.key, bundle: .module).widgetAccentable(true)

                    }
                if LogoutView.showText(for: widgetFamily) {
                    Text(Strings.notLogged.key, bundle: .module)
                }
            }
            .widgetAccentable(widgetFamily == .accessoryRectangular)
        }
    }
}

#if DEBUG
#Preview("LogoutView") {
    LogoutView(getURL: { _ in return .mock }, mode: .selectableMultiDevices)
}

#Preview("LogoutView Static") {
    LogoutView(getURL: { _ in return .mock }, mode: .turnOffAllDevices)
}
#endif
