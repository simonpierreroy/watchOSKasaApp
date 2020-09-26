import Foundation
import ComposableArchitecture
import Combine
import Tagged
import UserClient
import KasaCore

public enum UserAction {
    case logout
    case set(User?)
    case save
    case loadSavedUser
    case login(User.Credential)
    case send(Error)
    case errorHandled
}

public struct UserState {
    public static let empty = UserState(user: nil, isLoading: false, error: nil)
    
    public var user: User?
    public var isLoading: Bool
    public var error: Error?
}


public let userReducer = Reducer<UserState, UserAction, UserEnvironment>  { state, action, environment in
    
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
            .receive(on: environment.mainQueue)
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
