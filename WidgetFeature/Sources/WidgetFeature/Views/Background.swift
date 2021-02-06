//
//  SwiftUIView.swift
//  
//
//  Created by Simon-Pierre Roy on 2/6/21.
//

import SwiftUI

struct BackgroundWidget: View {
    
    var body: some View {
        ContainerRelativeShape().fill(
            LinearGradient(
                gradient: Gradient(
                    colors: [.backgroudStart, .backgroudEnd]
                ),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#if DEBUG
struct BackgroundWidget_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            BackgroundWidget()
                .previewDisplayName("Background Darck")
                .environment(\.colorScheme, .dark)
            BackgroundWidget()
                .previewDisplayName("Background")
                .environment(\.colorScheme, .light)
        }
    }
}
#endif
