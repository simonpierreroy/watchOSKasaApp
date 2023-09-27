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
import WidgetClient
import WidgetKit

struct WidgetView<I: AppIntent>: View {

    let logged: Bool
    let devices: [FlattenDevice]
    let newIntent: (FlattenDevice?) -> I
    let getURL: (AppLink) -> URL
    let mode: WidgetEntryMode

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
                StackList(devices: devices, newIntent: newIntent, getURL: getURL, mode: mode)
            } else {
                LogoutView(getURL: getURL, mode: mode)
            }
        }
        .containerBackground(for: .widget) {
            WidgetView.getBackground(for: widgetFamily)
        }
    }
}

public enum WidgetEntryMode {
    case selectableMultiDevices
    case turnOffAllDevices
}

public struct KasaAppWidgetEntryView<I: AppIntent>: View {

    public init(
        entry: DataDeviceEntry,
        newIntent: @escaping (FlattenDevice?) -> I,
        getURL: @escaping (AppLink) -> URL,
        mode: WidgetEntryMode
    ) {
        self.entry = entry
        self.newIntent = newIntent
        self.getURL = getURL
        self.mode = mode
    }

    public let entry: DataDeviceEntry
    public let newIntent: (FlattenDevice?) -> I
    public let mode: WidgetEntryMode
    public let getURL: (AppLink) -> URL

    public var body: some View {
        WidgetView(
            logged: entry.userIsLogged,
            devices: entry.devices,
            newIntent: newIntent,
            getURL: getURL,
            mode: mode
        )
    }
}
