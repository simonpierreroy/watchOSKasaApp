//
//  Color.swift
//  KasaAppWidgetExtension
//
//  Created by Simon-Pierre Roy on 10/29/20.
//  Copyright © 2020 Simon. All rights reserved.
//

//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 9/19/20.
//

import SwiftUI

extension Color {
    static let backgroudEnd = Self("backgroud_end")
    static let backgroudStart = Self("backgroud_start")
    static let button = Self("button")

}

#if DEBUG
import WidgetKit
struct Color_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            VStack {
                Text("backgroud_end").foregroundColor(.backgroudEnd)
                Text("backgroud_start").foregroundColor(.backgroudStart)
                Text("button").foregroundColor(.button)
            }.preferredColorScheme(.light)
            .previewDisplayName("light")
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            VStack {
                Text("backgroud_end").foregroundColor(.backgroudEnd)
                Text("backgroud_start").foregroundColor(.backgroudStart)
                Text("button").foregroundColor(.button)
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("dark")
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            
        }
    }
}

#endif
