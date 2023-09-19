//
//  UserLogin.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/30/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import BaseUI
import ComposableArchitecture
import Foundation
import SwiftUI
import UserClient

#if os(watchOS)
public struct UserLoginViewWatch: View {

    public init(
        store: Store<StateView, Action>
    ) {
        self.store = store
    }

    private let store: Store<StateView, Action>

    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView {
                Image(systemName: "person.circle")
                    .font(.title)
                    .foregroundColor(Color.orange)
                    .padding()

                Group {
                    TextField(
                        Strings.logEmail.string,
                        text: viewStore.binding(get: \.email, send: { .bind(.setEmail($0)) })
                    )
                    .textContentType(.emailAddress)
                    SecureField(
                        Strings.logPassword.string,
                        text: viewStore.binding(get: \.password, send: { .bind(.setPassword($0)) })
                    )
                    .textContentType(.password)

                    Button {
                        viewStore.send(.tappedLoginButton)
                    } label: {
                        LoadingView(.constant(viewStore.isLoadingUser)) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                Text(Strings.loginApp.key, bundle: .module)
                            }
                        }
                    }
                }
                .disabled(viewStore.isLoadingUser)
            }
            .alert(
                store: self.store.scope(
                    state: \.$alert,
                    action: { .alert($0) }
                )
            )

        }
    }
}

extension UserLoginViewWatch {

    public struct StateView: Equatable {
        let isLoadingUser: Bool
        let email: String
        let password: String
        @PresentationState var alert: AlertState<UserLogoutReducer.Action.Alert>?
    }

    public enum Action: Equatable {
        case tappedLoginButton
        case bind(UserLogoutReducer.Action.Bind)
        case alert(PresentationAction<UserLogoutReducer.Action.Alert>)
    }
}

extension UserLoginViewWatch.StateView {
    public init(
        userLogoutState: UserLogoutReducer.State
    ) {

        self.isLoadingUser = userLogoutState.isLoading
        self.password = userLogoutState.password
        self.email = userLogoutState.email
        self.alert = userLogoutState.alert
    }
}

extension UserLogoutReducer.Action {
    public init(
        userViewAction: UserLoginViewWatch.Action
    ) {
        switch userViewAction {
        case .alert(let action):
            self = .alert(action)
        case .tappedLoginButton:
            self = .login
        case .bind(let bindingAction):
            self = .bind(bindingAction)
        }
    }
}

#if DEBUG
#Preview("Login") {
    UserLoginViewWatch(
        store:
            Store(
                initialState: .empty,
                reducer: { UserLogoutReducer() }
            )
            .scope(
                state: UserLoginViewWatch.StateView.init(userLogoutState:),
                action: UserLogoutReducer.Action.init(userViewAction:)
            )
    )
}

#Preview("Login Failed") {
    UserLoginViewWatch(
        store:
            Store(
                initialState: .empty,
                reducer: {
                    UserLogoutReducer().dependency(\.userClient, .mockFailed())

                }
            )
            .scope(
                state: UserLoginViewWatch.StateView.init(userLogoutState:),
                action: UserLogoutReducer.Action.init(userViewAction:)
            )
    )
}

#Preview("Login French") {
    UserLoginViewWatch(
        store:
            Store(
                initialState: .empty,
                reducer: { UserLogoutReducer() }
            )
            .scope(
                state: UserLoginViewWatch.StateView.init(userLogoutState:),
                action: UserLogoutReducer.Action.init(userViewAction:)
            )
    )
    .environment(\.locale, .init(identifier: "fr"))
}

#Preview("Loading") {
    UserLoginViewWatch(
        store:
            Store(
                initialState: .init(email: "", password: "", isLoading: true),
                reducer: { UserLogoutReducer() }
            )
            .scope(
                state: UserLoginViewWatch.StateView.init(userLogoutState:),
                action: UserLogoutReducer.Action.init(userViewAction:)
            )
    )
}
#endif
#endif
