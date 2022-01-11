import Foundation
import ComposableArchitecture
import Combine
import Tagged
import UserClient
import KasaCore

public enum UserAction {
    case logout
    case set(User)
    case save
    case loadSavedUser
    case login(User.Credential)
    case send(Error)
    case errorHandled
}

public struct UserState {
    public static let empty = Self(status: .logout, route: nil)
    
    public struct LoggedUserState {
        public var user: User
    }
    
    public enum UserStatus {
        case logged(LoggedUserState)
        case loading
        case logout
    }
    
    public enum Route {
        case error(Error)
    }
    
    public var status: UserStatus
    public var route: Route?
}


public let userReducer = Reducer<UserState, UserAction, UserEnvironment> { state, action, environment in
    
    switch action {
    case .logout:
        state.status = .logout
        return Just(UserAction.save).eraseToEffect()
    case .set(let user):
        state.status = .logged(.init(user: user))
        return Just(UserAction.save).eraseToEffect()
    case .save:
        let userToSave: User?
        switch state.status {
        case .logout, .loading: userToSave = nil
        case .logged(let stateUser): userToSave = stateUser.user
        }
        return environment
            .cache
            .save(userToSave)
            .flatMap{ environment.reloadAppExtensions }
            .flatMap(Empty.completeImmediately)
            .subscribe(on: environment.backgroundQueue)
            .receive(on: environment.mainQueue)
            .eraseToEffect()
    case .loadSavedUser:
        state.status = .loading
        return environment
            .cache
            .load
            .map { user in
                if let user = user {
                    return UserAction.set(user)
                } else {
                    return UserAction.logout
                }
            }
            .subscribe(on: environment.backgroundQueue)
            .receive(on: environment.mainQueue)
            .eraseToEffect()
    case .login(let credential):
        state.status = .loading
        return environment
            .login(credential)
            .map(\.token >>> User.init(token:) >>> UserAction.set)
            .catch(UserAction.send >>> Just.init)
            .receive(on: environment.mainQueue)
            .eraseToEffect()
    case .send(let error):
        state.status = .logout
        state.route = .error(error)
        return .none
    case .errorHandled:
        state.route = nil
        return .none
    }
}
