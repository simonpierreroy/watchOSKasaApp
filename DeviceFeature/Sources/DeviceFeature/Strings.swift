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
    case kasaName = "kasa_name"
}

extension Strings {
    var key: LocalizedStringKey {
        .init(self.rawValue)
    }

    var string: String {
        NSLocalizedString(self.rawValue, bundle: .module, comment: "")
    }
}
