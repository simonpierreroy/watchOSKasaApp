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
        return Effect(value: .save)
    case .set(let user):
        state.status = .logged(.init(user: user))
        return Effect(value: .save)
    case .save:
        let userToSsave = (/UserState.UserStatus.logged).extract(from: state.status)?.user
        return .fireAndForget {
            await environment.cache.save(userToSsave)
            await environment.reloadAppExtensions()
        }
    case .loadSavedUser:
        state.status = .loading
        return .task {
            if let user = await environment.cache.load() {
                return .set(user)
            } else {
                return .logout
            }
        }
    case .login(let credential):
        state.status = .loading
        return Effect.task {
            let token = try await environment.login(credential).token
            return .set(.init(token: token))
        } catch : { error in
            return .send(error)
        }.animation()
    case .send(let error):
        state.status = .logout
        state.route = .error(error)
        return .none
    case .errorHandled:
        state.route = nil
        return .none
    }
}
