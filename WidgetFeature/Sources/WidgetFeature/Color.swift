//
//  Color.swift
//  KasaAppWidgetExtension
//
//  Created by Simon-Pierre Roy on 10/29/20.
//  Copyright © 2020 Simon. All rights reserved.

import Foundation
import SwiftUI

extension Color {
    static let backgroundEnd = Self("background_end", bundle: .module)
    static let backgroundStart = Self("background_start", bundle: .module)
    static let button = Self("button", bundle: .module)

}

#if DEBUG
import WidgetKit
struct Color_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                Text("background_end").foregroundColor(.backgroundEnd)
                Text("background_start").foregroundColor(.backgroundStart)
                Text("button").foregroundColor(.button)
            }
            .preferredColorScheme(.light)
            .previewDisplayName("light")

            VStack {
                Text("background_end").foregroundColor(.backgroundEnd)
                Text("background_start").foregroundColor(.backgroundStart)
                Text("button").foregroundColor(.button)
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("dark")

        }
    }
}

#endif
