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
        .map { i in Device.init(id: "\(i)", name: "Here is device no \(i)", state: .relay(false)) }.flatten()

    let getURL: (AppLink) -> URL
    let staticIntent: Bool

    @Environment(\.widgetFamily) var widgetFamily

    static func showBackground(widgetFamily: WidgetFamily) -> Bool {
        switch widgetFamily {
        case .accessoryInline, .accessoryRectangular, .accessoryCircular:
            return false
        case .systemMedium, .systemSmall, .systemLarge, .systemExtraLarge:
            return true
        @unknown default:
            return false
        }
    }

    static func showText(widgetFamily: WidgetFamily) -> Bool {
        switch widgetFamily {
        case .accessoryCircular:
            return false
        case .systemMedium, .systemSmall, .systemLarge, .systemExtraLarge, .accessoryInline, .accessoryRectangular:
            return true
        @unknown default:
            return false
        }
    }

    static func imageFont(widgetFamily: WidgetFamily) -> Font {
        switch widgetFamily {
        case .accessoryRectangular:
            return .body
        case .systemMedium, .systemSmall, .systemLarge, .systemExtraLarge, .accessoryInline, .accessoryCircular:
            return .largeTitle
        @unknown default:
            return .largeTitle
        }
    }

    var body: some View {
        ZStack {
            if LogoutView.showBackground(widgetFamily: widgetFamily) {
                StackList(devices: LogoutView.logoutDevicesPreview, getURL: getURL, staticIntent: staticIntent)
                    .blur(radius: 4.0)
            }
            VStack {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(LogoutView.imageFont(widgetFamily: widgetFamily))
                if LogoutView.showText(widgetFamily: widgetFamily) {
                    Text(Strings.notLogged.key, bundle: .module)
                }
            }
        }
    }
}

#if DEBUG
struct LogoutView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LogoutView(getURL: { _ in return .mock }, staticIntent: false)
                .previewDisplayName("LogoutView")
            LogoutView(getURL: { _ in return .mock }, staticIntent: true)
                .previewDisplayName("LogoutView Static")
        }
    }
}
#endif
