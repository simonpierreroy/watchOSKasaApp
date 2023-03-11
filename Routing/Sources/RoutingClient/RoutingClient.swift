//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 8/15/22.
//

import Dependencies
import DeviceClient
import Foundation
import KasaCore
import XCTestDynamicOverlay

public enum AppLink {
    case devices(DevicesLink)
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

extension URLRouter: TestDependencyKey {
    public static var testValue = URLRouter(
        parse: XCTUnimplemented("\(Self.self).parse", placeholder: .devices(.turnOffAllDevices)),
        print: XCTUnimplemented("\(Self.self).print", placeholder: .mock)
    )

    public static let previewValue = URLRouter.mock(link: .devices(.turnOffAllDevices), print: nil)
}

extension DependencyValues {
    public var urlRouter: URLRouter {
        get { self[URLRouter.self] }
        set { self[URLRouter.self] = newValue }
    }
}

extension URLRouter {
    public static func mock(link: AppLink, print url: URL?) -> Self {
        Self(
            parse: { _ in link },
            print: { _ in url ?? .mock }
        )
    }
}
