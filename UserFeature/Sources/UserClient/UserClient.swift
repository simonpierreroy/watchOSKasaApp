import Dependencies
import DependenciesMacros
import Foundation
import KasaCore
import Tagged
import XCTestDynamicOverlay

@DependencyClient
public struct UserClient: Sendable {
    public let login: @Sendable (User.Credential) async throws -> User
    public let refreshToken: @Sendable (User.RefreshToken, User.TerminalId) async throws -> Token
}

extension UserClient: TestDependencyKey {
    public static let testValue = Self()
    public static let previewValue: UserClient = .mock()
}

extension DependencyValues {
    public var userClient: UserClient {
        get { self[UserClient.self] }
        set { self[UserClient.self] = newValue }
    }
}

extension UserClient {
    public static func mock(waitFor delay: Duration = .seconds(2), refresh: Bool = false) -> Self {
        Self(
            login: { _ in
                try await taskSleep(for: delay)
                return .mock
            },
            refreshToken: { _, _ in
                try await taskSleep(for: delay)
                return "1-refreshed"
            }
        )
    }
}

#if DEBUG
private struct MockUserClientError: Error {}

extension UserClient {
    public static func mockFailed(waitFor delay: Duration = .seconds(2)) -> Self {
        Self(
            login: { _ in
                try await taskSleep(for: delay)
                throw MockUserClientError()
            },
            refreshToken: { _, _ in
                try await taskSleep(for: delay)
                throw MockUserClientError()
            }
        )
    }
}
#endif
