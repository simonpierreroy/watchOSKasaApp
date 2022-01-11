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
    
    private static let validDeviceID =  Prefix(1...) { $0.isNumber || $0.isLetter }
    
    private static let validDeviceLink = StartsWith(Link.baseURL.absoluteString)
        .take(validDeviceID)
        .skip(End())
        .map(String.init)
        .map(Device.ID.init(rawValue:))
        .map(Link.device)

    
    private static let invalidLink = StartsWith(Link.invalidURL.absoluteString)
        .skip(End())
        .map{ Link.invalid }

    private static let deviceLink = validDeviceLink
        .orElse(invalidLink)
    
    static func parserDeepLink(url: URL) -> Self {
        parserDeepLink(string: url.absoluteString)
    }
    
    private static func parserDeepLink(string: String) -> Self {
        guard let link = deviceLink.parse(string[...]) else {
              return .error
          }
          return link
      }
}


