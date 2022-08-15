//
//  SwiftUIView.swift
//  
//
//  Created by Simon-Pierre Roy on 2/6/21.
//

import SwiftUI
import DeviceClient


public struct WidgetView: View {
    
    public init (
        logged: Bool,
        devices: [Device],
        getURL: @escaping (DeviceClient.Link) -> URL
    ) {
        self.logged = logged
        self.devices = devices
        self.getURL = getURL
    }
    
    let logged: Bool
    let devices: [Device]
    let getURL: (DeviceClient.Link) -> URL
    
    public var body: some View {
        VStack {
            if logged {
                StackList(devices: devices, getURL: getURL)
            } else {
                LogoutView(getURL: getURL)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BackgroundWidget())
    }
}
