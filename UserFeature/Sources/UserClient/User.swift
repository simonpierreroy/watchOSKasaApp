import Foundation
import KasaCore
import Tagged

public struct User: Equatable, Codable {
    public enum RefreshTokenTag {}
    public typealias RefreshToken = Tagged<RefreshTokenTag, String>

    public enum TerminalIdTag {}
    public typealias TerminalId = Tagged<TerminalIdTag, UUID>

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

    public struct TokenInfo: Equatable, Codable {

        public init(
            token: Token,
            refreshToken: RefreshToken,
            creationDate: Date
        ) {
            self.token = token
            self.refreshToken = refreshToken
            self.creationDate = creationDate
        }

        public let token: Token
        public let refreshToken: RefreshToken
        public let creationDate: Date
    }

    public var tokenInfo: TokenInfo
    public let terminalId: TerminalId
    public let email: String

    public init(
        token: Token,
        refreshToken: RefreshToken,
        creationDateForToken: Date,
        terminalId: TerminalId,
        email: String
    ) {
        self.tokenInfo = .init(token: token, refreshToken: refreshToken, creationDate: creationDateForToken)
        self.terminalId = terminalId
        self.email = email
    }
}

extension User {
    public static let mock = Self(
        token: "1",
        refreshToken: "refresh-1",
        creationDateForToken: .now,
        terminalId: .init(.mockZero),
        email: "test@test.ca"
    )
}
