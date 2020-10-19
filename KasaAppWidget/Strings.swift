//
//  Strings.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 10/3/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Foundation


extension LocalizedStringKey {
    static let no_device: Self = "no_device"
    static let not_logged: Self = "not_logged"
    static let description_widget: Self = "description_widget"


}

#if DEBUG
import SwiftUI
import WidgetKit


struct Strings_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            VStack {
                Text(.not_logged)
                Text(.no_device)
                Text(.description_widget)
            }.previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("English")
            VStack {
                Text(.not_logged)
                Text(.no_device)
                Text(.description_widget)
            }.environment(\.locale, .init(identifier: "fr"))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Français")
        }
    }
}
#endif
