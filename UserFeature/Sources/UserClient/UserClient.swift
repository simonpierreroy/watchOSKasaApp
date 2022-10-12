import Tagged
import KasaCore
import Foundation
import Dependencies
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

public extension DependencyValues {
    var userClient: UserClient {
        get { self[UserClient.self] }
        set { self[UserClient.self] = newValue }
    }
}

public extension UserClient {
    static func mock(waitFor seconds: Duration = .seconds(2)) -> Self {
        Self { _ in
            try await taskSleep(for: seconds)
            return .mock
        }
    }
}
