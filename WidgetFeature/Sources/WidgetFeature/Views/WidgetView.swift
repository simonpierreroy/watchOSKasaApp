//
//  SwiftUIView.swift
//  
//
//  Created by Simon-Pierre Roy on 2/6/21.
//

import SwiftUI
import DeviceClient
import RoutingClient
import WidgetKit

public struct WidgetView: View {
    
    public init (
        logged: Bool,
        devices: [Device],
        getURL: @escaping (AppLink) -> URL,
        staticIntent: Bool
    ) {
        self.logged = logged
        self.devices = devices
        self.getURL = getURL
        self.staticIntent = staticIntent
    }
    
    let logged: Bool
    let devices: [Device]
    let getURL: (AppLink) -> URL
    let staticIntent: Bool
    
    @Environment(\.widgetFamily) var widgetFamily
    
    @ViewBuilder
    static func getBackground(for widgetFamily: WidgetFamily) -> some View {
        Group {
            switch widgetFamily {
            case  .accessoryCircular, .accessoryInline:
                AccessoryWidgetBackground()
            case  .accessoryRectangular:
                EmptyView()
            case .systemMedium, .systemSmall, .systemLarge, .systemExtraLarge :
                GradientBackgroundWidget()
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
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(WidgetView.getBackground(for: widgetFamily))
    }
}
