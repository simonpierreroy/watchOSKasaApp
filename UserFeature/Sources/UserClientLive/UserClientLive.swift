import Combine
import ComposableArchitecture
import Foundation
import KasaCore
import KasaNetworking
import UserClient

extension User.Credential {
    func networkCredential() -> Networking.App.Credential {
        return .init(email: self.email, password: self.password)
    }
}

extension UserClient: DependencyKey {
    public static let liveValue = UserClient(
        login: login(with:),
        refreshToken: refreshToken(_:terminalUUID:)
    )
}

@Sendable
private func shouldRefreshToken(from tokenInfo: User.TokenInfo) -> Bool {
    guard let expirationDate = Calendar.current.date(byAdding: .day, value: 1, to: tokenInfo.creationDate) else {
        return false
    }
    return Date.now > expirationDate
}

@Sendable
private func login(with credential: User.Credential) async throws -> User {
    let newTerminalID = User.TerminalId.init(rawValue: UUID())
    let info = try await Networking.App.login(with: credential.networkCredential(), terminalUUID: newTerminalID)
    return User(
        token: .init(rawValue: info.token),
        refreshToken: .init(rawValue: info.refreshToken),
        creationDateForToken: .now,
        terminalId: newTerminalID,
        email: info.email
    )
}

@Sendable
private func refreshToken(_ refresh: User.RefreshToken, terminalUUID: User.TerminalId) async throws -> Token {
    try await Networking.App.refreshToken(with: refresh, terminalUUID: terminalUUID)
}
