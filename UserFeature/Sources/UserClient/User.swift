import Foundation
import KasaCore

public struct User: Equatable {

    public struct Credential: Codable, Equatable {
        public init(
            email: String,
            password: String
        ) {
            self.email = email
            self.password = password
        }
        public let email: String
        public let password: String
    }

    public let token: Token

    public init(
        token: Token
    ) {
        self.token = token
    }
}

extension User {
    public static let mock = Self(token: "1")
}
