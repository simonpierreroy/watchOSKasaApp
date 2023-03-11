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
    case noDevice = "no_device"
    case noDeviceSelected = "no_device_selected"
    case notLogged = "not_logged"
    case descriptionWidget = "description_widget"
    case turnOff = "turn_off"
    case deviceGroup = "device_group"
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
        Group {
            VStack {
                Text(Strings.notLogged.key, bundle: .module)
                Text(Strings.noDevice.key, bundle: .module)
                Text(Strings.descriptionWidget.key, bundle: .module)
                Text(Strings.turnOff.key, bundle: .module)
                Text(Strings.deviceGroup.key, bundle: .module)
                Text(Strings.noDeviceSelected.key, bundle: .module)
            }
            .previewDisplayName("English")
            VStack {
                Text(Strings.notLogged.key, bundle: .module)
                Text(Strings.noDevice.key, bundle: .module)
                Text(Strings.descriptionWidget.key, bundle: .module)
                Text(Strings.turnOff.key, bundle: .module)
                Text(Strings.deviceGroup.key, bundle: .module)
                Text(Strings.noDeviceSelected.key, bundle: .module)
            }
            .environment(\.locale, .init(identifier: "fr"))
            .previewDisplayName("Français")
        }
    }
}
#endif
