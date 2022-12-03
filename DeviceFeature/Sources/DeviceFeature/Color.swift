//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 9/19/20.
//

import SwiftUI

extension Color {
    static let logout = Self("logout", bundle: .module)
    static let valid = Self("valid", bundle: .module)
    static let tile = Self("tile", bundle: .module)
    static let moon = Self("moon", bundle: .module)

}

#if DEBUG
struct Color_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                Text("logout").foregroundColor(.logout)
                Text("valid").foregroundColor(.valid)
                Text("moon").foregroundColor(.moon)
                Text("tile").foregroundColor(.tile)
            }
            .preferredColorScheme(.light)
            .previewDisplayName("light")

            VStack {
                Text("logout").foregroundColor(.logout)
                Text("valid").foregroundColor(.valid)
                Text("moon").foregroundColor(.moon)
                Text("tile").foregroundColor(.tile)
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("dark")

        }
    }
}

#endif
