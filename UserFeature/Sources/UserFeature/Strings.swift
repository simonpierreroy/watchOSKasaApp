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
                Text(Strings.loginApp.key, bundle: .module)
                Text(Strings.logEmail.key, bundle: .module)
                Text(Strings.logPassword.key, bundle: .module)
            }
            .previewDisplayName("English")
            VStack {
                Text(Strings.loginApp.key, bundle: .module)
                Text(Strings.logEmail.key, bundle: .module)
                Text(Strings.logPassword.key, bundle: .module)
            }
            .environment(\.locale, .init(identifier: "fr"))
            .previewDisplayName("Français")
        }
    }
}
#endif
