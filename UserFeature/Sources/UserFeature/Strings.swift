//
//  String.swift
//
//
//  Created by Simon-Pierre Roy on 9/19/20.
//

import Foundation
import SwiftUI

enum Strings: String {
    case loginApp = "login_app"
    case logEmail = "log_email"
    case logPassword = "log_password"
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
