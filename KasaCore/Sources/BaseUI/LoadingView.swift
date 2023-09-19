//
//  LoadingImage.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/31/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import SwiftUI

public struct LoadingView<Content: View>: View {
    @Binding var loading: Bool
    let content: () -> Content

    public init(
        _ loading: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
        self._loading = loading
    }

    public var body: some View {
        if loading {
            ProgressView()
        } else {
            content()
        }
    }
}

#if DEBUG
#Preview {
    LoadingView(.constant(true)) { Text("test") }
}
#endif
