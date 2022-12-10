//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 8/15/22.
//

import Dependencies
import DeviceClient
import DeviceClientLive
import Foundation
import Parsing
import RoutingClient

extension AppLink {

    private static let deviceEntryLink = ParsePrint(.case(Self.devices)) {
        StartsWith<Substring>("devices/")
        DevicesLink.devices
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

extension URLRouter: DependencyKey {
    public static var liveValue = Self(
        parse: AppLink.parserDeepLink(url:),
        print: AppLink.getURL(link:)
    )
}
