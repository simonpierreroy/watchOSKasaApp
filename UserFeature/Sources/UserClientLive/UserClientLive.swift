import KasaNetworking
import UserClient
import ComposableArchitecture
import Combine
import KasaCore

extension User.Credential {
    func networkCredential() -> Networking.App.Credential {
        return .init(email: self.email, password: self.password)
    }
}

public extension UserEnvironment {
    
    private static let userKey = "userToken"
    
    @Sendable
    static func liveLogginEffect(credential: User.Credential) async throws -> User {
        let info = try await Networking.App.login(cred: credential.networkCredential())
        return User(token: .init(rawValue: info.token))
    }
    
    @Sendable
    static func liveSave(user: User?) async -> Void {
        UserDefaults.kasaAppGroup.setValue(user?.token.rawValue, forKeyPath: UserEnvironment.userKey)
    }
    
    @Sendable
    static func liveLoadUser() async -> User? {
        if let token = UserDefaults.kasaAppGroup.string(forKey:  UserEnvironment.userKey) {
            return User.init(token: .init(rawValue: token))
        }
        return nil
    }
}

public extension UserCache {
    static let live = Self(save: UserEnvironment.liveSave, load: UserEnvironment.liveLoadUser)
}
