//
//  SwiftUIView.swift
//  
//
//  Created by Simon-Pierre Roy on 2/6/21.
//

import SwiftUI
import DeviceClient
import RoutingClient

struct LogoutView: View {
    static let logoutDevicesPreview = (1...10)
        .map { i in Device.init(id: "\(i)", name: "Here is device no \(i)", state: false) }
    
    let getURL: (AppLink) -> URL
    
    var body: some View {
        ZStack {
            StackList(devices: LogoutView.logoutDevicesPreview, getURL: getURL)
                .blur(radius: 4.0)
            VStack {
                Image(systemName: "keyboard")
                    .font(.largeTitle)
                    .padding()
                Text(Strings.not_logged.key, bundle: .module)
            }
        }
    }
}

#if DEBUG
struct LogoutView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LogoutView(getURL: { _ in return .mock })
                .previewDisplayName("LogoutView")
        }
    }
}
#endif
