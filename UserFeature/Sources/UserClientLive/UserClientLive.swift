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
    public static let liveValue = UserClient(login: login(with:))
}

@Sendable
private func login(with credential: User.Credential) async throws -> User {
    let info = try await Networking.App.login(with: credential.networkCredential())
    return User(token: .init(rawValue: info.token))
}
