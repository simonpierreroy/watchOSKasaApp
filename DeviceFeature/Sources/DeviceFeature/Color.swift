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
    
}

struct Color_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("logout").foregroundColor(.logout)
            Text("valid").foregroundColor(.valid)
        }
    }
}
