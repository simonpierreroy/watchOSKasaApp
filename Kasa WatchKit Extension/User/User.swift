//
//  User.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/30/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Foundation
import ComposableArchitecture
import Combine
import Tagged

struct User: Equatable {
    typealias Token = Tagged<User, String>
    let token: Token
}

enum UserAction {
    case logout
    case set(User?)
    case save
    case loadSavedUser
    case login(Networking.App.Credential)
    case send(Error)
    case errorHandled
}

struct UserState {
    static let empty = UserState(user: nil, isLoading: false, error: nil)
    
    var user: User?
    var isLoading: Bool
    var error: Error?
}

struct UserEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let backgroundQueue: AnySchedulerOf<DispatchQueue>
    let login: (Networking.App.Credential) -> AnyPublisher<User, Error>
    let cache: UserCache
}

extension UserEnvironment {
    init(appEnv: AppEnv) {
        self.mainQueue = appEnv.mainQueue
        self.backgroundQueue = appEnv.backgroundQueue
        self.login = appEnv.login
        self.cache = appEnv.cache
    }
}

struct UserCache {
    let save: (User?) -> Effect<Void, Never>
    let load: Effect<User?, Never>
}

let userReducer = Reducer<UserState, UserAction, UserEnvironment>  { state, action, environment in
    
    switch action {
    case .logout:
        return Just(UserAction.set(nil)).eraseToEffect()
    case .set(let user):
        state.isLoading = false
        state.user = user
        return Just(UserAction.save).eraseToEffect()
    case .save:
        return environment
            .cache
            .save(state.user)
            .flatMap(Empty.completeImmediately)
            .eraseToEffect()
        
    case .loadSavedUser:
        state.isLoading = true
        return environment
            .cache
            .load
            .map(UserAction.set)
            .subscribe(on: environment.backgroundQueue)
            .receive(on: environment.mainQueue)
            .eraseToEffect()
        
    case .login(let credential):
        state.isLoading = true
        return environment
            .login(credential)
            .map(\.token >>> User.init(token:) >>> UserAction.set)
            .catch(UserAction.send >>> Just.init)
            .receive(on: environment.mainQueue)
            .eraseToEffect()
        
    case .send(let error):
        state.isLoading = false
        state.error = error
        return .none
    case .errorHandled:
        state.error = nil
        return .none
    }
}

extension UserEnvironment {
    static func liveLogginEffect(credential: Networking.App.Credential) -> AnyPublisher<User, Error> {
        return  Networking.App
            .login(cred: credential)
            .map(\.token >>> User.Token.init(rawValue:) >>> User.init(token:))
            .eraseToAnyPublisher()
    }
    
    static func liveSave(user: User?) -> Effect<Void, Never> {
        return .run { subscriber in
            UserDefaults.standard.setValue(user?.token.rawValue, forKeyPath: "userToken")
            subscriber.send(completion: .finished)
            return AnyCancellable{}
        }
    }
    
    
    static let liveLoadUser: Effect<User?, Never> = .run { subscriber in
        
        let user = UserDefaults.standard.string(forKey: "userToken")
            .map(User.Token.init(rawValue:) >>> User.init(token:))
        
        subscriber.send(user)
        subscriber.send(completion: .finished)
        return AnyCancellable{}
    }
}

#if DEBUG
extension UserEnvironment {
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

