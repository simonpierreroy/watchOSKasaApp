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
        getURL: @escaping (AppLink) -> URL
    ) {
        self.logged = logged
        self.devices = devices
        self.getURL = getURL
    }
    
    let logged: Bool
    let devices: [Device]
    let getURL: (AppLink) -> URL
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
                StackList(devices: devices, getURL: getURL)
            } else {
                LogoutView(getURL: getURL)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(WidgetView.getBackground(for: widgetFamily))
    }
}
