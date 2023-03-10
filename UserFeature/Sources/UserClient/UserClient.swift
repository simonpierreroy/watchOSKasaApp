import Dependencies
import Foundation
import KasaCore
import Tagged
import XCTestDynamicOverlay

public struct UserClient {

    public init(
        login: @escaping @Sendable (User.Credential) async throws -> User
    ) {
        self.login = login
    }

    public let login: @Sendable (User.Credential) async throws -> User
}

extension UserClient: TestDependencyKey {
    public static let testValue = Self(
        login: XCTUnimplemented("\(Self.self).login", placeholder: .mock)
    )

    public static let previewValue: UserClient = .mock()
}

extension DependencyValues {
    public var userClient: UserClient {
        get { self[UserClient.self] }
        set { self[UserClient.self] = newValue }
    }
}

extension UserClient {
    public static func mock(waitFor delay: Duration = .seconds(2)) -> Self {
        Self { _ in
            try await taskSleep(for: delay)
            return .mock
        }
    }
}

#if DEBUG
private struct MockUserClientError: Error {}

extension UserClient {
    public static func mockFailed(waitFor delay: Duration = .seconds(2)) -> Self {
        Self { _ in
            try await taskSleep(for: delay)
            throw MockUserClientError()
        }
    }
}
#endif
