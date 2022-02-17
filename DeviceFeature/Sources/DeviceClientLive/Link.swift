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
        
    private static let validDeviceLink = Parse(
        String.init >>> Device.ID.init(rawValue:) >>> Link.device
    ) {
        StartsWith<Substring>(Link.baseURL.absoluteString)
        Prefix(1...) { $0.isNumber || $0.isLetter }
        End()
    }
    
    private static let invalidLink = Parse(Link.invalid) {
        StartsWith<Substring>(Link.invalidURL.absoluteString)
        End()
    }
    
    private static let closeAllLink = Parse(Link.closeAll) {
        StartsWith<Substring>(Link.cloaseAllURL.absoluteString)
        End()
    }
    
    private static let deviceLink = OneOf {
        validDeviceLink
        invalidLink
        closeAllLink
    }
    
    static func parserDeepLink(url: URL) -> Self {
        parserDeepLink(string: url.absoluteString)
    }
    
    private static func parserDeepLink(string: String) -> Self {
        do {
            return try deviceLink.parse(string[...])
        } catch {
            return .error
        }
      }
}


