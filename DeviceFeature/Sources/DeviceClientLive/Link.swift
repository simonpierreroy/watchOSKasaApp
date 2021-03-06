//
//  File.swift
//  
//
//  Created by Simon-Pierre Roy on 10/5/20.
//

import DeviceClient
import KasaCore
import Foundation

extension String {
    init<S>(characters: S) where S : Sequence, S.Element == Character {
        self.init(characters)
    }
}

extension Link {
    
    private static let validDeviceID =  Parser<Character>
        .oneOf(.number, .letter)
        .oneOrMore()
    
    private static let validDeviceLink: Parser<Self> = Parser
        .prefix(Link.baseURL.absoluteString)
        .take(validDeviceID)
        .skip(.end)
        .map(String.init(characters:))
        .map(Device.ID.init(rawValue:))
        .map(Link.device)
    
    private static let invalidLink: Parser<Self> = Parser<Void>
        .prefix(Link.invalidURL.absoluteString)
        .skip(.end)
        .map{ Link.invalid }
    
    private static let deviceLink: Parser<Self> = .oneOf(invalidLink, validDeviceLink)
    
    private static func parserDeepLink(string: String) -> Self {
        guard let link = deviceLink.run(string).match  else {
            return .error
        }
        return link
    }
    
    static func parserDeepLink(url: URL) -> Self {
        parserDeepLink(string: url.absoluteString)
    }
}


