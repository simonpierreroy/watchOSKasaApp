//
//  File.swift
//  
//
//  Created by Simon-Pierre Roy on 8/15/22.
//

import Foundation
import Parsing
import DeviceClientLive
import DeviceClient

public enum AppLink {
    case device(DeviceClient.Link)
}

extension AppLink {
    
    private static let deviceEntryLink = ParsePrint(.case(Self.device)) {
        StartsWith<Substring>("device/")
        DeviceClient.Link.deviceLinkParser
    }
    
    public static let appLinkParser = OneOf {
        deviceEntryLink
    }
    
    @Sendable
    static func parserDeepLink(url: URL) throws -> Self {
        return try appLinkParser.parse(url.absoluteString[...])
    }
    
    @Sendable
    static func getURL(link: Self) throws -> URL {
        let rawURL = String(try appLinkParser.print(link))
        guard let url = URL(string: rawURL) else {
            throw NSError(domain: "Invalid string to URL for DeepLink", code: -1)
        }
        return url
    }
}

public extension AppLink {
    struct URLRouter {
        public init(
            parse: @escaping @Sendable (URL) throws -> AppLink,
            print: @escaping @Sendable (AppLink) throws -> URL
        ) {
            self.parse = parse
            self.print = print
        }
        public let parse: @Sendable (URL) throws -> AppLink
        public let print: @Sendable (AppLink) throws -> URL
    }
}

public extension AppLink.URLRouter {
    static let live = Self(
        parse: AppLink.parserDeepLink(url:),
        print: AppLink.getURL(link:)
    )
}

#if DEBUG
public extension AppLink.URLRouter {
    static let mockDeviceIdOne = Self(
        parse: { _ in .device(.closeAll) },
        print: { _ in URL(string: "mockURL")! }
    
    )
}
#endif
