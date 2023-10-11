//
//  SwiftUIView.swift
//
//
//  Created by Simon-Pierre Roy on 2/6/21.
//

import SwiftUI

struct GradientBackgroundWidget: View {

    var body: some View {
        ContainerRelativeShape()
            .fill(
                LinearGradient(
                    gradient: Gradient(
                        colors: [.backgroundStart, .backgroundEnd]
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}

#if DEBUG
#Preview {
    GradientBackgroundWidget()
}
#endif
