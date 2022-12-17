import Combine
import ComposableArchitecture
import Foundation
import KasaCore
import Tagged
import UserClient

public struct UserReducer: ReducerProtocol {

    public init() {}

    public enum Action {
        case errorHandled
        case loginUser(UserLoginReducer.Action)
        case logoutUser(UserLogoutReducer.Action)
    }

    public struct State {
        public static let empty = Self(
            status: .logout(.empty),
            route: nil
        )

        public enum UserStatus {
            case logged(UserLoginReducer.State)
            case logout(UserLogoutReducer.State)
        }

        public enum Route {
            case error(Error)
        }

        public var status: UserStatus
        public var route: Route?
    }

    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \.status, action: .self) {
            EmptyReducer()
                .ifCaseLet(/State.UserStatus.logout, action: /Action.logoutUser) {
                    UserLogoutReducer()
                }
                .ifCaseLet(/State.UserStatus.logged, action: /Action.loginUser) {
                    UserLoginReducer()
                }
        }
        Reduce { state, action in
            switch action {
            case .errorHandled:
                state.route = nil
                return .none
            case .logoutUser(.setError(let error)):
                state.route = .error(error)
                return .none
            case .loginUser(.logout):
                state.status = .logout(.empty)
                return .none
            case .logoutUser(.setUser(let user)):
                state.status = .logged(.init(user: user))
                return .task { .loginUser(.save) }
            case .logoutUser, .loginUser:
                return .none
            }
        }
    }
}

public struct UserLoginReducer: ReducerProtocol {
    public struct State: Equatable {
        public var user: User
    }

    public enum Action {
        case save
        case logout
    }

    @Dependency(\.userCache) var userCache
    @Dependency(\.reloadAppExtensions) var reloadAppExtensions

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .save:
            return .run { [user = state.user] send in
                await userCache.save(user)
                await reloadAppExtensions()
            }
        case .logout:
            return .run { send in
                await userCache.save(nil)
                await reloadAppExtensions()
            }
        }
    }
}

public struct UserLogoutReducer: ReducerProtocol {

    public struct State {
        public static let empty = State(email: "", password: "", isLoading: false)
        public var email: String
        public var password: String
        public var isLoading: Bool
    }

    public enum Action {
        case setEmail(String)
        case setPassword(String)
        case resetEmailPassword
        case login
        case setError(Error)
        case setUser(User)
        case loadSavedUser
    }

    @Dependency(\.userClient) var client
    @Dependency(\.userCache) var userCache
    @Dependency(\.reloadAppExtensions) var reloadAppExtensions

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .setEmail(let email):
            guard email != state.email else { return .none }
            state.email = email
            return .none
        case .setPassword(let password):
            guard password != state.password else { return .none }
            state.password = password
            return .none
        case .resetEmailPassword:
            state.email = ""
            state.password = ""
            return .none
        case .login:
            state.isLoading = true
            let credential = User.Credential(email: state.email, password: state.password)
            return
                .run { send in
                    let token = try await client.login(credential).token
                    await send(.setUser(.init(token: token)), animation: .default)
                } catch: { error, send in
                    await send(.setError(error))
                }
        case .loadSavedUser:
            return .run { send in
                guard let user = await userCache.load() else { return }
                await send(.setUser(user))
            }
        case .setUser:
            state.isLoading = false
            return .run { _ in await reloadAppExtensions() }
        case .setError:
            state.isLoading = false
            return .none
        }
    }
}
