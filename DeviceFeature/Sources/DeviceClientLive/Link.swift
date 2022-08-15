//
//  File.swift
//  
//
//  Created by Simon-Pierre Roy on 10/5/20.
//

import DeviceClient
import KasaCore
import Foundation
import Parsing

extension Link {
    
    private static let validDeviceToggleLink = ParsePrint {
        StartsWith<Substring>("toggle/")
        Prefix(1...) { $0.isNumber || $0.isLetter }
        End()
    }.map(.string)
        .map(.memberwise(Device.ID.init(rawValue:)))
        .map(.case(Link.device))
        
    private static let closeAllLink = ParsePrint(.case(Link.closeAll)) {
        StartsWith<Substring>("closeAll")
        End()
    }
    
    public static let deviceLinkParser = OneOf {
        validDeviceToggleLink
        closeAllLink
    }
}


