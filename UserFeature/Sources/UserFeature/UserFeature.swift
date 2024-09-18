import Combine
import ComposableArchitecture
import Foundation
import KasaCore
import Tagged
import UserClient

@Reducer
public struct UserReducer: Sendable {

    public init() {}

    public enum Action {
        case loggedUser(UserLoggedReducer.Action)
        case logoutUser(UserLogoutReducer.Action)
    }

    @ObservableState
    public struct State: Sendable {
        public static func empty(with broadcastToken: Shared<Token?>) -> Self {
            .init(userLogState: .logout(.empty), broadcastToken: broadcastToken)
        }

        @CasePathable @dynamicMemberLookup
        public enum UserLogState: Sendable {
            case logged(UserLoggedReducer.State)
            case logout(UserLogoutReducer.State)
        }

        public var userLogState: UserLogState
        @Shared var broadcastToken: Token?
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loggedUser(.delegate(.logout)):
                state = .empty(with: state.$broadcastToken)
                return .none
            case .logoutUser(.delegate(.setUser(let user))):
                state = .init(
                    userLogState: .logged(
                        .init(
                            user: user,
                            broadcastToken: state.$broadcastToken
                        )
                    ),
                    broadcastToken: state.$broadcastToken
                )
                return .send(.loggedUser(.save))
            case .logoutUser, .loggedUser:
                return .none
            }
        }
        .ifLet(\.userLogState.logout, action: \.logoutUser) {
            UserLogoutReducer()
        }
        .ifLet(\.userLogState.logged, action: \.loggedUser) {
            UserLoggedReducer()
        }
    }
}

@Reducer
public struct UserLoggedReducer: Sendable {

    @ObservableState
    public struct State: Equatable, Sendable {

        init(user: User, broadcastToken: Shared<Token?>) {
            self.user = user
            self._broadcastToken = broadcastToken
            broadcastToken.wrappedValue = user.tokenInfo.token
        }

        public var user: User
        @Shared var broadcastToken: Token?
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

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .save:
            return .run { [user = state.user] send in
                try await userCache.save(user)
                await reloadAppExtensions()
            }
        case .delegate(.logout):
            state.broadcastToken = nil
            return .run { send in
                try await userCache.save(nil)
                await reloadAppExtensions()
            }
        }
    }
}

@Reducer
public struct UserLogoutReducer: Sendable {

    @ObservableState
    public struct State: Sendable {
        public static let empty = State(email: "", password: "", isLoading: false, alert: nil)

        public var email: String
        public var password: String
        public var isLoading: Bool
        @Presents public var alert: AlertState<Action.Alert>?
    }

    public enum Action: BindableAction, Sendable {

        public enum Delegate: Sendable {
            case setUser(User)
        }

        public enum Alert: Equatable, Sendable {}

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

    public var body: some ReducerOf<Self> {
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
        .ifLet(\.$alert, action: \.alert)
        BindingReducer()
    }
}
