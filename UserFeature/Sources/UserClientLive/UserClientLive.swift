import KasaNetworking
import UserClient
import ComposableArchitecture
import Combine
import KasaCore
#if canImport(WidgetKit)
import WidgetKit
#endif

extension User.Credential {
    func networkCredential() -> Networking.App.Credential {
        return .init(email: self.email, password: self.password)
    }
}

public extension UserEnvironment {
    static func liveLogginEffect(credential: User.Credential) -> AnyPublisher<User, Error> {
        return  Networking.App
            .login(cred: credential.networkCredential())
            .map(\.token >>> Token.init(rawValue:) >>> User.init(token:))
            .eraseToAnyPublisher()
    }
    
    static func liveSave(user: User?) -> Effect<Void, Never> {
        return .run { subscriber in
            UserDefaults.kasaAppGroup.setValue(user?.token.rawValue, forKeyPath: "userToken")
            #if canImport(WidgetKit)
                WidgetCenter.shared.reloadAllTimelines()
            #endif
            subscriber.send(completion: .finished)
            return AnyCancellable{}
        }
    }
    
    
    static let liveLoadUser: Effect<User?, Never> = .run { subscriber in
        
        let user = UserDefaults.kasaAppGroup.string(forKey: "userToken")
            .map(Token.init(rawValue:) >>> User.init(token:))
        
        subscriber.send(user)
        subscriber.send(completion: .finished)
        return AnyCancellable{}
    }
}
