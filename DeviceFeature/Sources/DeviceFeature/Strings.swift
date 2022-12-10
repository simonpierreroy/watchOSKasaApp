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
    case closeAll = "close_all"
    case deviceGroup = "device_group"
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
                Text(Strings.closeAll.key, bundle: .module)
                Text(Strings.deviceGroup.key, bundle: .module)
            }
            .previewDisplayName("English")
            VStack {
                Text(Strings.logoutApp.key, bundle: .module)
                Text(Strings.refreshList.key, bundle: .module)
                Text(Strings.closeAll.key, bundle: .module)
                Text(Strings.deviceGroup.key, bundle: .module)
            }
            .environment(\.locale, .init(identifier: "fr"))
            .previewDisplayName("Français")
        }
    }
}
#endif
