import Dependencies
import Foundation
import KasaCore
import Tagged
import XCTestDynamicOverlay

public struct UserCache {
    public init(
        save: @escaping @Sendable (User?) async -> Void,
        load: @escaping @Sendable () async -> User?,
        loadBlocking: @escaping @Sendable () -> User?

    ) {
        self.save = save
        self.load = load
        self.loadBlocking = loadBlocking
    }

    public let save: @Sendable (User?) async -> Void
    public let load: @Sendable () async -> User?
    public let loadBlocking: @Sendable () -> User?
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
