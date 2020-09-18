import ComposableArchitecture
import Combine
import Tagged
import KasaCore


public struct User: Equatable {
    
    public struct Credential: Codable, Equatable {
        public init(email: String, password: String) {
            self.email = email
            self.password = password
        }
        public let email: String
        public let password: String
    }
    
    public let token: Token
    
    public init(token: Token) {
        self.token = token
    }
}

public struct UserEnvironment {
    
    public init(
        mainQueue: AnySchedulerOf<DispatchQueue>,
        backgroundQueue: AnySchedulerOf<DispatchQueue>,
        login: @escaping (User.Credential) -> AnyPublisher<User, Error>,
        cache: UserCache) {
        
        self.mainQueue = mainQueue
        self.backgroundQueue = backgroundQueue
        self.login = login
        self.cache = cache
    }
    
    public let mainQueue: AnySchedulerOf<DispatchQueue>
    public let backgroundQueue: AnySchedulerOf<DispatchQueue>
    public let login: (User.Credential) -> AnyPublisher<User, Error>
    public let cache: UserCache
}


public struct UserCache {
    public init(
        save: @escaping (User?) -> Effect<Void, Never>,
        load: Effect<User?, Never>
    ) {
        self.save = save
        self.load = load
    }
    
    public let save: (User?) -> Effect<Void, Never>
    public let load: Effect<User?, Never>
}

#if DEBUG
public extension UserEnvironment {
    static let mockUserEnv: UserEnvironment = .init(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        backgroundQueue: DispatchQueue.main.eraseToAnyScheduler(),
        login:  { _ in Effect.future { $0(.success(User.init(token: "1"))) }
            .delay(for: 2, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
        },
        cache: UserCache(
            save: { _ in Effect<Void, Never>.fireAndForget {} } ,
            load: Just(Optional.some(User.init(token: "1")))
                .eraseToEffect()
        )
    )
}
#endif
