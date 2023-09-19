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

struct LogoutView: View {
    static let logoutDevicesPreview = (1...10)
        .map { i in Device.init(id: "\(i)", name: "Here is device no \(i)", details: .status(relay: false, info: .mock))
        }
        .flatten()

    let getURL: (AppLink) -> URL
    let staticIntent: Bool

    @Environment(\.widgetFamily) var widgetFamily

    static func showBackground(for widgetFamily: WidgetFamily) -> Bool {
        switch widgetFamily {
        case .accessoryInline, .accessoryRectangular, .accessoryCircular, .accessoryCorner:
            return false
        case .systemMedium, .systemSmall, .systemLarge, .systemExtraLarge:
            return true
        @unknown default:
            return false
        }
    }

    static func showText(for widgetFamily: WidgetFamily) -> Bool {
        switch widgetFamily {
        case .accessoryCircular, .accessoryCorner:
            return false
        case .systemMedium, .systemSmall, .systemLarge, .systemExtraLarge, .accessoryInline, .accessoryRectangular:
            return true
        @unknown default:
            return false
        }
    }

    static func imageFont(for widgetFamily: WidgetFamily) -> Font {
        switch widgetFamily {
        case .accessoryRectangular:
            return .body
        case .systemMedium, .systemSmall, .systemLarge, .systemExtraLarge, .accessoryInline, .accessoryCircular,
            .accessoryCorner:
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
        ZStack {
            if LogoutView.showBackground(for: widgetFamily) {
                StackList(devices: LogoutView.logoutDevicesPreview, getURL: getURL, staticIntent: staticIntent)
                    .blur(radius: 4.0)
            }
            VStack {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(LogoutView.imageFont(for: widgetFamily))
                    .widgetLabelOptional(active: TurnOffView.showWidgetText(for: widgetFamily)) {
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
    LogoutView(getURL: { _ in return .mock }, staticIntent: false)
}

#Preview("LogoutView Static") {
    LogoutView(getURL: { _ in return .mock }, staticIntent: true)
}
#endif
