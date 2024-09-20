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
    case emptyString = "empty_string"
    case canNotDisplay = "can_not_display"
}

extension Strings {
    public var key: LocalizedStringKey {
        .init(self.rawValue)
    }

    public var string: String {
        NSLocalizedString(self.rawValue, bundle: .module, comment: "")
    }
}
