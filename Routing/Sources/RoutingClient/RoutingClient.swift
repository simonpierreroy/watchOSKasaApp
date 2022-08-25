//
//  File.swift
//  
//
//  Created by Simon-Pierre Roy on 8/15/22.
//

import Foundation
import DeviceClient
import KasaCore

public enum AppLink {
    case device(DeviceClient.Link)
}

public struct URLRouter {
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

#if DEBUG
public extension URLRouter {
    static func mock(link: AppLink, print url: URL?) -> Self  {
        Self(
            parse: { _ in link },
            print: { _ in url ?? .mock }
        )
    }
}
#endif
