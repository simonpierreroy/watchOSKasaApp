//
//  String.swift
//  
//
//  Created by Simon-Pierre Roy on 9/19/20.
//

import Foundation
import SwiftUI

enum Strings: String {
    case logout_app
    case refresh_list
    case close_all
    case device_group
}


extension Strings {
    var key: LocalizedStringKey {
        .init(self.rawValue)
    }
    
    var string: String {
        NSLocalizedString( self.rawValue, bundle: .module, comment: "")
    }
}

#if DEBUG 

struct Strings_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            VStack {
                Text(Strings.logout_app.key, bundle: .module)
                Text(Strings.refresh_list.key, bundle: .module)
                Text(Strings.close_all.key, bundle: .module)
                Text(Strings.device_group.key, bundle: .module)
            }.previewDisplayName("English")
            VStack {
                Text(Strings.logout_app.key, bundle: .module)
                Text(Strings.refresh_list.key, bundle: .module)
                Text(Strings.close_all.key, bundle: .module)
                Text(Strings.device_group.key, bundle: .module)
            }.environment(\.locale, .init(identifier: "fr"))
            .previewDisplayName("Français")
        }
    }
}
#endif

