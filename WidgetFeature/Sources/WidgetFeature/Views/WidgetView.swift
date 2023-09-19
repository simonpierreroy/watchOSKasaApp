//
//  SwiftUIView.swift
//
//
//  Created by Simon-Pierre Roy on 2/6/21.
//

import DeviceClient
import RoutingClient
import SwiftUI
import WidgetClient
import WidgetKit

public struct WidgetView: View {

    public init(
        logged: Bool,
        devices: [FlattenDevice],
        getURL: @escaping (AppLink) -> URL,
        staticIntent: Bool
    ) {
        self.logged = logged
        self.devices = devices
        self.getURL = getURL
        self.staticIntent = staticIntent
    }

    let logged: Bool
    let devices: [FlattenDevice]
    let getURL: (AppLink) -> URL
    let staticIntent: Bool

    @Environment(\.widgetFamily) var widgetFamily

    @ViewBuilder
    static func getBackground(for widgetFamily: WidgetFamily) -> some View {
        Group {
            switch widgetFamily {
            case .accessoryCircular, .accessoryInline:
                AccessoryWidgetBackground()
            case .accessoryRectangular, .accessoryCorner:
                EmptyView()
            #if os(iOS)
            case .systemMedium, .systemSmall, .systemLarge, .systemExtraLarge:
                GradientBackgroundWidget()
            #endif
            @unknown default:
                EmptyView()
            }
        }
    }

    public var body: some View {
        VStack {
            if logged {
                StackList(devices: devices, getURL: getURL, staticIntent: staticIntent)
            } else {
                LogoutView(getURL: getURL, staticIntent: staticIntent)
            }
        }
        .containerBackground(for: .widget) {
            WidgetView.getBackground(for: widgetFamily)
        }
    }
}

public struct KasaAppWidgetEntryView: View {

    public init(
        entry: DataDeviceEntry,
        getURL: @escaping (AppLink) -> URL,
        staticIntent: Bool
    ) {
        self.entry = entry
        self.getURL = getURL
        self.staticIntent = staticIntent
    }

    public let entry: DataDeviceEntry
    public let getURL: (AppLink) -> URL
    public let staticIntent: Bool

    public var body: some View {
        WidgetView(
            logged: entry.userIsLogged,
            devices: entry.devices,
            getURL: getURL,
            staticIntent: staticIntent
        )
    }
}
