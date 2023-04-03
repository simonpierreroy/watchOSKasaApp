import Dependencies
import Foundation
import KasaCore
import Tagged
import XCTestDynamicOverlay

public struct UserCache {

    public enum Failure: Error {
        case dataConversion
    }

    public init(
        save: @escaping @Sendable (User?) async throws -> Void,
        load: @escaping @Sendable () async throws -> User?,
        loadBlocking: @escaping @Sendable () throws -> User?

    ) {
        self.save = save
        self.load = load
        self.loadBlocking = loadBlocking
    }

    public let save: @Sendable (User?) async throws -> Void
    public let load: @Sendable () async throws -> User?
    public let loadBlocking: @Sendable () throws -> User?
}

extension UserCache: TestDependencyKey {
    public static let testValue = Self(
        save: XCTUnimplemented("\(Self.self).save"),
        load: XCTUnimplemented("\(Self.self).load", placeholder: nil),
        loadBlocking: XCTUnimplemented("\(Self.self).loadBlocking", placeholder: nil)
    )

    public static let previewValue: UserCache = .mock
}

extension DependencyValues {
    public var userCache: UserCache {
        get { self[UserCache.self] }
        set { self[UserCache.self] = newValue }
    }
}

extension UserCache {
    public static let mock = Self(
        save: { _ in return },
        load: { return .mock },
        loadBlocking: { return .mock }
    )
}
