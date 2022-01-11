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
    static func liveLogginEffect(credential: User.Credential) -> AnyPublisher<User, Error> {
        return Effect.task {
            let info = try await Networking.App.login(cred: credential.networkCredential())
            return User(token: .init(rawValue: info.token))
        }.eraseToAnyPublisher()
    }
    
    static func liveSave(user: User?) -> AnyPublisher<Void, Never> {
        return Effect.future { work in
            UserDefaults.kasaAppGroup.setValue(user?.token.rawValue, forKeyPath: "userToken")
            work(.success(()))
        }.eraseToAnyPublisher()
    }
    
    
    static let liveLoadUser: AnyPublisher<User?, Never> = Effect.future { work in
        let user = UserDefaults.kasaAppGroup.string(forKey: "userToken")
            .map(Token.init(rawValue:) >>> User.init(token:))
        work(.success(user))
    }.eraseToAnyPublisher()
}

public extension UserCache {
    static let live = Self(save: UserEnvironment.liveSave, load: UserEnvironment.liveLoadUser)
}
