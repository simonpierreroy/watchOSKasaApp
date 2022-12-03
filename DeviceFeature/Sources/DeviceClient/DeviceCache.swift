import Combine
import ComposableArchitecture
import Foundation
import KasaCore
import Tagged
import XCTestDynamicOverlay

public struct DevicesCache {
    public enum Failure: Error {
        case dataConversion
    }

    public init(
        save: @escaping @Sendable ([Device]) async throws -> Void,
        load: @escaping @Sendable () async throws -> [Device],
        loadBlocking: @escaping @Sendable () throws -> [Device]
    ) {
        self.save = save
        self.load = load
        self.loadBlocking = loadBlocking
    }

    public let save: @Sendable ([Device]) async throws -> Void
    public let load: @Sendable () async throws -> [Device]
    public let loadBlocking: @Sendable () throws -> [Device]

}

extension DevicesCache: TestDependencyKey {
    public static let previewValue = DevicesCache.mock
    public static let testValue = DevicesCache(
        save: XCTUnimplemented("\(Self.self).save"),
        load: XCTUnimplemented("\(Self.self).load", placeholder: [.debugDevice1]),
        loadBlocking: XCTUnimplemented("\(Self.self).loadBlocking", placeholder: [.debugDevice1])
    )
}

extension DependencyValues {
    public var devicesCache: DevicesCache {
        get { self[DevicesCache.self] }
        set { self[DevicesCache.self] = newValue }
    }
}

extension DevicesCache {
    public static let mock = Self(
        save: { _ in return },
        load: {
            [
                .debugDevice1,
                .debugDevice2,
                .debugDevice3,
            ]
        },
        loadBlocking: { [.debugDevice1, .debugDevice2, .debugDevice3] }
    )
}
