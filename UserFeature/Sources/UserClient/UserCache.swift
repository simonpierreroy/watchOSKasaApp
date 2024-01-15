import Dependencies
import DependenciesMacros
import Foundation
import KasaCore
import Tagged
import XCTestDynamicOverlay

@DependencyClient
public struct UserCache: Sendable {

    public enum Failure: Error {
        case dataConversion
    }

    public var save: @Sendable (User?) async throws -> Void
    public var load: @Sendable () async throws -> User?
    public var loadBlocking: @Sendable () throws -> User?
}

extension UserCache: TestDependencyKey {
    public static let testValue = Self()
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
