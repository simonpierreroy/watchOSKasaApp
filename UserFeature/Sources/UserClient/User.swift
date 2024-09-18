import Foundation
import KasaCore
import Tagged

public struct User: Equatable, Codable, Sendable {
    public enum RefreshTokenTag {}
    public typealias RefreshToken = Tagged<RefreshTokenTag, String>

    public enum TerminalIdTag {}
    public typealias TerminalId = Tagged<TerminalIdTag, UUID>

    public struct Credential: Codable, Equatable, Sendable {
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

    public struct TokenInfo: Equatable, Codable, Sendable {

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

        public func isExpired(for calendar: Calendar, now: Date) -> Bool {
            if let expiration = calendar.date(byAdding: .hour, value: 6, to: self.creationDate) {
                return now > expiration
            }
            return false
        }

        public func newInfoWithUpdatedToken(to token: Token, now: Date) -> Self {
            return TokenInfo(token: token, refreshToken: self.refreshToken, creationDate: now)
        }
    }

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

    public var tokenInfo: TokenInfo
    public let terminalId: TerminalId
    public let email: String

    public mutating func updateToken(to newToken: Token, now: Date) {
        self.tokenInfo = self.tokenInfo.newInfoWithUpdatedToken(to: newToken, now: now)
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
