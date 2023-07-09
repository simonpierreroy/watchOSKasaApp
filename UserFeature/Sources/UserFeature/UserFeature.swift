import Combine
import ComposableArchitecture
import Foundation
import KasaCore
import Tagged
import UserClient

public struct UserReducer: ReducerProtocol {

    public init() {}

    public enum Action {
        case loggedUser(UserLoggedReducer.Action)
        case logoutUser(UserLogoutReducer.Action)
    }

    public enum State {
        public static let empty = Self.logout(.empty)
        case logged(UserLoggedReducer.State)
        case logout(UserLogoutReducer.State)
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .loggedUser(.delegate(.logout)):
                state = .logout(.empty)
                return .none
            case .logoutUser(.delegate(.setUser(let user))):
                state = .logged(.init(user: user))
                return .task { .loggedUser(.save) }
            case .logoutUser, .loggedUser:
                return .none
            }
        }
        .ifCaseLet(/State.logout, action: /Action.logoutUser) {
            UserLogoutReducer()
        }
        .ifCaseLet(/State.logged, action: /Action.loggedUser) {
            UserLoggedReducer()
        }
    }
}

public struct UserLoggedReducer: ReducerProtocol {
    public struct State: Equatable {
        public var user: User
    }

    public enum Action {
        public enum Delegate {
            case logout
        }

        case save
        case delegate(Delegate)
    }

    @Dependency(\.userCache) var userCache
    @Dependency(\.reloadAppExtensions) var reloadAppExtensions

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .save:
            return .run { [user = state.user] send in
                try await userCache.save(user)
                await reloadAppExtensions()
            }
        case .delegate(.logout):
            return .run { send in
                try await userCache.save(nil)
                await reloadAppExtensions()
            }
        }
    }
}

public struct UserLogoutReducer: ReducerProtocol {

    public struct State {
        public static let empty = State(email: "", password: "", isLoading: false, alert: nil)

        @BindingState public var email: String
        @BindingState public var password: String
        public var isLoading: Bool
        @PresentationState public var alert: AlertState<Action.Alert>?
    }

    public enum Action: BindableAction {

        public enum Delegate {
            case setUser(User)
        }

        public enum Alert: Equatable {}

        case login
        case noUserInCacheFound
        case loadSavedUser
        case setError(Error)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)
        case binding(BindingAction<State>)
    }

    @Dependency(\.userClient) var client
    @Dependency(\.userCache) var userCache
    @Dependency(\.reloadAppExtensions) var reloadAppExtensions
    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now

    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .login:
                guard state.isLoading == false else { return .none }
                state.isLoading = true
                let credential = User.Credential(email: state.email, password: state.password)
                return
                    .run { send in
                        let user = try await client.login(credential)
                        await send(.delegate(.setUser(user)), animation: .default)
                    } catch: { error, send in
                        await send(.setError(error))
                    }
            case .loadSavedUser:
                guard state.isLoading == false else { return .none }
                state.isLoading = true
                return .run { send in
                    guard var user = try await userCache.load() else {
                        await send(.noUserInCacheFound)
                        return
                    }

                    if user.tokenInfo.isExpired(for: self.calendar, now: self.now) {
                        let newToken = try await self.client.refreshToken(user.tokenInfo.refreshToken, user.terminalId)
                        user.updateToken(to: newToken, now: self.now)
                    }

                    await send(.delegate(.setUser(user)))
                } catch: { error, send in
                    await send(.setError(error))
                }
            case .noUserInCacheFound:
                state.isLoading = false
                return .none
            case .delegate(.setUser):
                state.isLoading = false
                return .none
            case .setError(let error):
                state.isLoading = false
                state.alert = AlertState(title: { TextState(error.localizedDescription) })
                return .none
            case .alert:
                return .none
            case .binding:
                return .none
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
}
