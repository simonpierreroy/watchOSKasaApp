import ComposableArchitecture
import Foundation
import KasaCore
import UserClient

extension UserCache: DependencyKey {
    public static let liveValue = UserCache(
        save: save(user:),
        load: loadUser,
        loadBlocking: loadBlockingUser
    )
}

private let userKey = "userToken"

@Sendable
private func save(user: User?) async {
    UserDefaults.kasaAppGroup.setValue(user?.token.rawValue, forKeyPath: userKey)
}

@Sendable
private func loadBlockingUser() -> User? {
    if let token = UserDefaults.kasaAppGroup.string(forKey: userKey) {
        return User.init(token: .init(rawValue: token))
    }
    return nil
}

@Sendable
private func loadUser() async -> User? {
    return loadBlockingUser()
}
