//
//  LoadingImage.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/31/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import SwiftUI

struct LoadingImage: View {
    
    @Binding var loading: Bool
    let systemName: String
    
    var body: some View {
        Image(systemName: systemName)
            .rotationEffect(.degrees(loading ? 360 : 0 ))
            .animation(
                loading ? Animation.linear(duration: 2).repeatForever(autoreverses: false)
                    :  Animation.default
        )
    }
}

#if DEBUG
struct LoadingImage_Previews: PreviewProvider {
    static var previews: some View {
        LoadingImage(loading: .constant(true), systemName: "slowmo")
    }
}
#endif
