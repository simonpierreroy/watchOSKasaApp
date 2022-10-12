import Foundation
import ComposableArchitecture
import Combine
import Tagged
import UserClient
import KasaCore

public struct UserReducer: ReducerProtocol {
    
    public init() { }
    
    public enum Action {
        case logout
        case set(User)
        case save
        case loadSavedUser
        case login(User.Credential)
        case send(Error)
        case errorHandled
    }
    
    public struct State {
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
    
    @Dependency(\.userCache) var userCache
    @Dependency(\.userClient) var client
    @Dependency(\.reloadAppExtensions) var reloadAppExtensions
    
    public func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
        
        switch action {
        case .logout:
            state.status = .logout
            return Effect(value: .save)
        case .set(let user):
            state.status = .logged(.init(user: user))
            return Effect(value: .save)
        case .save:
            let userToSave = (/State.UserStatus.logged).extract(from: state.status)?.user
            return .fireAndForget {
                await userCache.save(userToSave)
                await reloadAppExtensions()
            }
        case .loadSavedUser:
            state.status = .loading
            return .task {
                if let user = await userCache.load() {
                    return .set(user)
                } else {
                    return .logout
                }
            }
        case .login(let credential):
            state.status = .loading
            return Effect.task {
                let token = try await client.login(credential).token
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
}
