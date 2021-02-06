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
        devices: [Device]
    ) {
        self.logged = logged
        self.devices = devices
    }
    
    let logged: Bool
    let devices: [Device]
    
    public var body: some View {
        VStack {
            if logged {
                StackList(devices: devices)
            } else {
                LogoutView()
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BackgroundWidget())
    }
}
