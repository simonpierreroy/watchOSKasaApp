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
        cache: UserCache,
        reloadAppExtensions: AnyPublisher<Void,Never>
    ) {
        
        self.mainQueue = mainQueue
        self.backgroundQueue = backgroundQueue
        self.login = login
        self.cache = cache
        self.reloadAppExtensions = reloadAppExtensions
    }
    
    public let mainQueue: AnySchedulerOf<DispatchQueue>
    public let backgroundQueue: AnySchedulerOf<DispatchQueue>
    public let login: (User.Credential) -> AnyPublisher<User, Error>
    public let cache: UserCache
    public let reloadAppExtensions: AnyPublisher<Void,Never>
}


public struct UserCache {
    public init(
        save: @escaping (User?) -> AnyPublisher<Void, Never>,
        load: AnyPublisher<User?, Never>
    ) {
        self.save = save
        self.load = load
    }
    
    public let save: (User?) -> AnyPublisher<Void, Never>
    public let load: AnyPublisher<User?, Never>
}

#if DEBUG
public extension UserCache {
    static let mock = Self(
        save: { _ in Empty(completeImmediately: true).eraseToAnyPublisher() } ,
        load: Just(Optional.some(User.init(token: "1")))
            .eraseToAnyPublisher()
    )
}

public extension UserEnvironment {
    static let mock = Self(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        backgroundQueue: DispatchQueue.main.eraseToAnyScheduler(),
        login:  { _ in Effect.future { $0(.success(User.init(token: "1"))) }
            .delay(for: 2, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
        },
        cache: .mock,
        reloadAppExtensions: Empty(completeImmediately: true).eraseToAnyPublisher()
    )
}
#endif
