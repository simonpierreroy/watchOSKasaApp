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

#if os(iOS)
public struct UserLoginViewiOS: View {

    public init(
        store: Store<StateView, Action>
    ) {
        self.store = store
    }

    private let store: Store<StateView, Action>

    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView {

                Text("Kasa").font(.largeTitle)
                Image(systemName: "light.max").font(.largeTitle)
                Spacer(minLength: 32)
                VStack {
                    HStack {
                        Image(systemName: "person.icloud")
                            .font(.title2)
                        TextField(
                            Strings.logEmail.string,
                            text: viewStore.binding(get: \.email, send: { .bind(.setEmail($0)) })
                        )
                        .textContentType(.emailAddress)

                    }
                    .padding()
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)

                    HStack {
                        Image(systemName: "key.icloud")
                            .font(.title2)

                        SecureField(
                            Strings.logPassword.string,
                            text: viewStore.binding(get: \.password, send: { .bind(.setPassword($0)) })
                        )
                        .textContentType(.password)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)

                    Spacer(minLength: 16)

                    Button {
                        viewStore.send(.tappedLoginButton)
                    } label: {
                        LoadingView(.constant(viewStore.isLoadingUser)) {
                            HStack {
                                Image(systemName: "arrow.forward.circle")
                                Text(Strings.loginApp.key, bundle: .module)

                            }
                            .foregroundColor(Color.green)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(32)
                }
                .disabled(viewStore.isLoadingUser)
                .frame(maxWidth: 500).padding()
            }
            .frame(maxWidth: .infinity)
            .alert(
                store: self.store.scope(
                    state: \.$alert,
                    action: { .alert($0) }
                )
            )

        }
        .foregroundColor(.orange)
    }
}

extension UserLoginViewiOS {

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

extension UserLoginViewiOS.StateView {
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
        userViewAction: UserLoginViewiOS.Action
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
struct UserLoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UserLoginViewiOS(
                store:
                    Store(
                        initialState: .empty,
                        reducer: { UserLogoutReducer() }
                    )
                    .scope(
                        state: UserLoginViewiOS.StateView.init(userLogoutState:),
                        action: UserLogoutReducer.Action.init(userViewAction:)
                    )
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Login")

            UserLoginViewiOS(
                store:
                    Store(
                        initialState: .empty,
                        reducer: {
                            UserLogoutReducer().dependency(\.userClient, .mockFailed())
                        }
                    )
                    .scope(
                        state: UserLoginViewiOS.StateView.init(userLogoutState:),
                        action: UserLogoutReducer.Action.init(userViewAction:)
                    )
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Login Failed")

            UserLoginViewiOS(
                store:
                    Store(
                        initialState: .empty,
                        reducer: { UserLogoutReducer() }
                    )
                    .scope(
                        state: UserLoginViewiOS.StateView.init(userLogoutState:),
                        action: UserLogoutReducer.Action.init(userViewAction:)
                    )
            )
            .environment(\.locale, .init(identifier: "fr"))
            .previewDisplayName("Login French")

            UserLoginViewiOS(
                store:
                    Store(
                        initialState: .init(email: "", password: "", isLoading: true),
                        reducer: { UserLogoutReducer() }
                    )
                    .scope(
                        state: UserLoginViewiOS.StateView.init(userLogoutState:),
                        action: UserLogoutReducer.Action.init(userViewAction:)
                    )
            )
            .previewDisplayName("Loading")
        }
    }
}
#endif
#endif
