//
//  File.swift
//  
//
//  Created by Simon-Pierre Roy on 9/19/20.
//

import SwiftUI

extension Color {
    static let logout = Color.init("logout", bundle: .module)
    static let valid = Color.init("valid", bundle: .module)
    
    static let moon = Color.init("moon", bundle: .module)
    
}

#if DEBUG
struct Color_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            VStack {
                Text("logout").foregroundColor(.logout)
                Text("valid").foregroundColor(.valid)
                Text("moon").foregroundColor(.moon)
            }.preferredColorScheme(.light)
            .previewDisplayName("light")
            
            VStack {
                Text("logout").foregroundColor(.logout)
                Text("valid").foregroundColor(.valid)
                Text("moon").foregroundColor(.moon)
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("dark")
            
        }
    }
}

#endif
