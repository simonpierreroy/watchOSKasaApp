//
//  Color.swift
//  KasaAppWidgetExtension
//
//  Created by Simon-Pierre Roy on 10/29/20.
//  Copyright © 2020 Simon. All rights reserved.


import Foundation
import SwiftUI

extension Color {
    static let backgroudEnd = Self("backgroud_end",bundle: .module)
    static let backgroudStart = Self("backgroud_start", bundle: .module)
    static let button = Self("button", bundle: .module)

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
            
            VStack {
                Text("backgroud_end").foregroundColor(.backgroudEnd)
                Text("backgroud_start").foregroundColor(.backgroudStart)
                Text("button").foregroundColor(.button)
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("dark")
            
        }
    }
}

#endif
