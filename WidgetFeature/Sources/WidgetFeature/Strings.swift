//
//  Strings.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 10/3/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Foundation
import SwiftUI

public enum Strings: String {
    case no_device
    case not_logged
    case description_widget
}

extension Strings {
    var key: LocalizedStringKey {
        .init(self.rawValue)
    }
    
    public var string: String {
        NSLocalizedString(self.rawValue, bundle: .module, comment: "")
    }
}

#if DEBUG
import WidgetKit


struct Strings_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            VStack {
                Text(Strings.not_logged.key, bundle: .module)
                Text(Strings.no_device.key, bundle: .module)
                Text(Strings.description_widget.key, bundle: .module)
            }
            .previewDisplayName("English")
            VStack {
                Text(Strings.not_logged.key,  bundle: .module)
                Text(Strings.no_device.key,  bundle: .module)
                Text(Strings.description_widget.key,  bundle: .module)
            }.environment(\.locale, .init(identifier: "fr"))
            .previewDisplayName("Français")
        }
    }
}
#endif
