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
        WithViewStore(self.store) { viewStore in
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
                            text: viewStore.binding(\.$email)
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
                            text: viewStore.binding(\.$password)
                        )
                        .textContentType(.password)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)

                    Spacer(minLength: 16)

                    Button {
                        viewStore.send(.tappedLogingButton)
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
                item: viewStore.binding(
                    get: { $0.errorMessageToDisplayText.map(AlertInfo.init(title:)) },
                    send: .tappedErrorAlert
                ),
                content: { Alert(title: Text($0.title)) }
            )

        }
        .foregroundColor(.orange)
    }
}

extension UserLoginViewiOS {
    struct AlertInfo: Identifiable {
        var title: String
        var id: String { self.title }
    }
}

extension UserLoginViewiOS {

    public struct StateView: Equatable {
        let errorMessageToDisplayText: String?
        let isLoadingUser: Bool
        @BindingState var email: String
        @BindingState var password: String
    }

    public enum Action: Equatable, BindableAction {
        case tappedErrorAlert
        case tappedLogingButton
        case binding(BindingAction<StateView>)
    }
}

extension UserLoginViewiOS.StateView {
    public init(
        userLogoutState: UserLogoutReducer.State
    ) {

        self.isLoadingUser = userLogoutState.isLoading
        switch userLogoutState.route {
        case nil:
            self.errorMessageToDisplayText = nil
        case .some(.error(let error)):
            self.errorMessageToDisplayText = error.localizedDescription
        }

        self.password = userLogoutState.password
        self.email = userLogoutState.email

    }
}

extension UserLogoutReducer.State {
    // How to map binding state
    fileprivate var viewBindingActionKey: UserLoginViewiOS.StateView {
        get { .init(errorMessageToDisplayText: nil, isLoadingUser: false, email: self.email, password: self.password) }
        set {
            self.password = newValue.password
            self.email = newValue.email
        }
    }
}

extension UserLogoutReducer.Action {
    public init(
        userViewAction: UserLoginViewiOS.Action
    ) {
        switch userViewAction {
        case .tappedErrorAlert:
            self = .errorHandled
        case .tappedLogingButton:
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
            UserLoginViewiOS(
                store:
                    Store(
                        initialState: .empty,
                        reducer: UserLogoutReducer()
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
                        reducer: UserLogoutReducer()
                            .dependency(\.userClient, .mockFailed())
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
                        reducer: UserLogoutReducer()
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
                        reducer: UserLogoutReducer()
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
