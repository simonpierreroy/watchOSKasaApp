//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 8/15/22.
//

import Dependencies
import DependenciesMacros
import DeviceClient
import Foundation
import KasaCore
import XCTestDynamicOverlay

public enum AppLink {
    case devices(DevicesLink)
}

@DependencyClient
public struct URLRouter {
    public let parse: @Sendable (URL) throws -> AppLink
    public let print: @Sendable (AppLink) throws -> URL
}

extension URLRouter: TestDependencyKey {
    public static var testValue = URLRouter()
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
