//
//  String.swift
//  
//
//  Created by Simon-Pierre Roy on 9/19/20.
//

import Foundation

enum Strings: String {
    case login_app
    case log_email
    case log_password
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
import SwiftUI

struct Strings_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            VStack {
                Text(Strings.login_app.key, bundle: .module)
                Text(Strings.log_email.key, bundle: .module)
                Text(Strings.log_password.key, bundle: .module)
            }.previewDisplayName("English")
            VStack {
                Text(Strings.login_app.key, bundle: .module)
                Text(Strings.log_email.key, bundle: .module)
                Text(Strings.log_password.key, bundle: .module)
            }.environment(\.locale, .init(identifier: "fr"))
            .previewDisplayName("Français")
        }
    }
}
#endif
