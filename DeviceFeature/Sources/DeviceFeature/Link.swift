//
//  File.swift
//  
//
//  Created by Simon-Pierre Roy on 10/5/20.
//

import DeviceClient
import KasaCore
import Foundation

public extension Link {
    
    private static let validDeviceID: Parser<[Character]> = .oneOrMore(
        .oneOf([.number, .letter]),
        separatedBy: .always(())
    )

    private static let validDeviceLink: Parser<Link> = zip(
        .prefix(Link.baseURL.absoluteString),
        validDeviceID
    ).map(\.1)
    .map{ String.init($0) }
    .map(Device.ID.init(rawValue:))
    .map(Link.device)

    private static let invalidLink: Parser<Link> = Parser<Void>.prefix(Link.invalidURL.absoluteString).map{ Link.invalid }

    private static let deviceLink: Parser<Link> = .oneOf([invalidLink, validDeviceLink])

    static func parserDeepLink(string: String) -> Link {
        let result = deviceLink.run(string)
        guard result.rest.isEmpty, let match = result.match  else {
            return .error
        }
        return match
    }
    
    static func parserDeepLink(url: URL) -> Link {
        parserDeepLink(string: url.absoluteString)
    }
}


