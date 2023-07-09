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
        WithViewStore(self.store) { viewStore in
            ScrollView {
                Image(systemName: "person.circle")
                    .font(.title)
                    .foregroundColor(Color.orange)
                    .padding()

                Group {
                    TextField(
                        Strings.logEmail.string,
                        text: viewStore.$email
                    )
                    .textContentType(.emailAddress)
                    SecureField(
                        Strings.logPassword.string,
                        text: viewStore.$password
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
        @BindingState var email: String
        @BindingState var password: String
        @PresentationState var alert: AlertState<UserLogoutReducer.Action.Alert>?
    }

    public enum Action: Equatable, BindableAction {
        case tappedLoginButton
        case binding(BindingAction<StateView>)
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

extension UserLogoutReducer.State {
    // How to map binding state
    fileprivate var viewBindingActionKey: UserLoginViewWatch.StateView {
        get { .init(isLoadingUser: false, email: self.email, password: self.password, alert: nil) }
        set {
            self.password = newValue.password
            self.email = newValue.email
        }
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
        case .binding(let action):
            self = .binding(action.pullback(\.viewBindingActionKey))
        }
    }
}

#if DEBUG
struct UserLoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UserLoginViewWatch(
                store:
                    Store(
                        initialState: .empty,
                        reducer: UserLogoutReducer()
                    )
                    .scope(
                        state: UserLoginViewWatch.StateView.init(userLogoutState:),
                        action: UserLogoutReducer.Action.init(userViewAction:)
                    )
            )
            .previewDisplayName("Login")

            UserLoginViewWatch(
                store:
                    Store(
                        initialState: .empty,
                        reducer: UserLogoutReducer().dependency(\.userClient, .mockFailed())
                    )
                    .scope(
                        state: UserLoginViewWatch.StateView.init(userLogoutState:),
                        action: UserLogoutReducer.Action.init(userViewAction:)
                    )
            )
            .previewDisplayName("Login Failed")

            UserLoginViewWatch(
                store:
                    Store(
                        initialState: .empty,
                        reducer: UserLogoutReducer()
                    )
                    .scope(
                        state: UserLoginViewWatch.StateView.init(userLogoutState:),
                        action: UserLogoutReducer.Action.init(userViewAction:)
                    )
            )
            .environment(\.locale, .init(identifier: "fr"))
            .previewDisplayName("Login French")

            UserLoginViewWatch(
                store:
                    Store(
                        initialState: .init(email: "", password: "", isLoading: true),
                        reducer: UserLogoutReducer()
                    )
                    .scope(
                        state: UserLoginViewWatch.StateView.init(userLogoutState:),
                        action: UserLogoutReducer.Action.init(userViewAction:)
                    )
            )
            .previewDisplayName("Loading")
        }
    }
}
#endif
#endif
