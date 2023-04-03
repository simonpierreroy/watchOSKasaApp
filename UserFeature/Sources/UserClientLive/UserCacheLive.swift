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
private let encoder = JSONEncoder()
private let decoder = JSONDecoder()

@Sendable
private func save(user: User?) async throws {

    guard let user else {
        UserDefaults.kasaAppGroup.setValue(nil, forKeyPath: userKey)
        return
    }

    let data = try encoder.encode(user)
    let string = String(data: data, encoding: .utf8)
    UserDefaults.kasaAppGroup.setValue(string, forKeyPath: userKey)
}

@Sendable
private func loadBlockingUser() throws -> User? {

    guard let stringData = UserDefaults.kasaAppGroup.string(forKey: userKey) else {
        return nil
    }

    guard let data = stringData.data(using: .utf8) else {
        throw UserCache.Failure.dataConversion
    }
    return try decoder.decode(User.self, from: data)

}

@Sendable
private func loadUser() async throws -> User? {
    return try loadBlockingUser()
}
