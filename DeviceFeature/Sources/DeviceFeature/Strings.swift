//
//  String.swift
//
//
//  Created by Simon-Pierre Roy on 9/19/20.
//

import Foundation
import SwiftUI

enum Strings: String {
    case logoutApp = "logout_app"
    case refreshList = "refresh_list"
    case turnOff = "turn_off"
    case deviceGroup = "device_group"
    case doneAction = "done_action"
    case model = "model"
    case hardwareVersion = "hardware_version"
    case softwareVersion = "software_version"
    case macAddress = "mac_address"

}

extension Strings {
    var key: LocalizedStringKey {
        .init(self.rawValue)
    }

    var string: String {
        NSLocalizedString(self.rawValue, bundle: .module, comment: "")
    }
}

#if DEBUG

struct Strings_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                Text(Strings.logoutApp.key, bundle: .module)
                Text(Strings.refreshList.key, bundle: .module)
                Text(Strings.turnOff.key, bundle: .module)
                Text(Strings.deviceGroup.key, bundle: .module)
                Text(Strings.doneAction.key, bundle: .module)
                Text(Strings.model.key, bundle: .module)
                Text(Strings.hardwareVersion.key, bundle: .module)
                Text(Strings.softwareVersion.key, bundle: .module)
                Text(Strings.macAddress.key, bundle: .module)
            }
            .previewDisplayName("English")
            VStack {
                Text(Strings.logoutApp.key, bundle: .module)
                Text(Strings.refreshList.key, bundle: .module)
                Text(Strings.turnOff.key, bundle: .module)
                Text(Strings.deviceGroup.key, bundle: .module)
                Text(Strings.doneAction.key, bundle: .module)
                Text(Strings.model.key, bundle: .module)
                Text(Strings.hardwareVersion.key, bundle: .module)
                Text(Strings.softwareVersion.key, bundle: .module)
                Text(Strings.macAddress.key, bundle: .module)
            }
            .environment(\.locale, .init(identifier: "fr"))
            .previewDisplayName("Français")
        }
    }
}
#endif
