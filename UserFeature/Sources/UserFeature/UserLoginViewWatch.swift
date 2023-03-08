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

                TextField(
                    Strings.logEmail.string,
                    text: viewStore.binding(\.$email)
                )
                .textContentType(.emailAddress)
                SecureField(
                    Strings.logPassword.string,
                    text: viewStore.binding(\.$password)
                )
                .textContentType(.password)

                Button {
                    viewStore.send(.tappedLogingButton)
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
            .alert(
                item: viewStore.binding(
                    get: { $0.errorMessageToDisplayText.map(AlertInfo.init(title:)) },
                    send: .tappedErrorAlert
                ),
                content: { Alert(title: Text($0.title)) }
            )

        }
    }
}

extension UserLoginViewWatch {
    struct AlertInfo: Identifiable {
        var title: String
        var id: String { self.title }
    }
}

extension UserLoginViewWatch {

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

extension UserLoginViewWatch.StateView {
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
    fileprivate var viewBindingActionKey: UserLoginViewWatch.StateView {
        get { .init(errorMessageToDisplayText: nil, isLoadingUser: false, email: self.email, password: self.password) }
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
