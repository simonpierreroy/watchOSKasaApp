import Tagged
import KasaCore
import Foundation

public struct User: Equatable {
    
    public struct Credential: Codable, Equatable {
        public init(email: String, password: String) {
            self.email = email
            self.password = password
        }
        public let email: String
        public let password: String
    }
    
    public let token: Token
    
    public init(token: Token) {
        self.token = token
    }
}

public struct UserEnvironment {
    
    public init(
        login: @escaping @Sendable (User.Credential) async throws -> User,
        cache: UserCache,
        reloadAppExtensions: @escaping @Sendable () async -> Void
    ) {
        self.login = login
        self.cache = cache
        self.reloadAppExtensions = reloadAppExtensions
    }
    
    public let login: @Sendable (User.Credential) async throws -> User
    public let cache: UserCache
    public let reloadAppExtensions: @Sendable () async -> Void
}


public struct UserCache {
    public init(
        save: @escaping @Sendable  (User?) async -> Void,
        load: @escaping @Sendable () async -> User?,
        loadBlocking: @escaping @Sendable () -> User?

    ) {
        self.save = save
        self.load = load
        self.loadBlocking = loadBlocking
    }
    
    public let save: @Sendable  (User?) async -> Void
    public let load: @Sendable () async -> User?
    public let loadBlocking: @Sendable () -> User?

}

#if DEBUG
public extension UserCache {
    static let mock = Self(
        save: { _ in return } ,
        load: { return  User.init(token: "1") },
        loadBlocking: { return  User.init(token: "1") }
    )
}

public extension UserEnvironment {
    static func mock(waitFor seconds: UInt64 = 2) -> Self {
        Self(login:  { _ in
            try await taskSleep(for: seconds)
            return User.init(token: "1")
        },
             cache: .mock,
             reloadAppExtensions: { return }
        )
    }
}
#endif
