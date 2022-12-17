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
                    text: viewStore.binding(get: { $0.email }, send: Action.typedEmail)
                )
                .textContentType(.emailAddress)
                SecureField(
                    Strings.logPassword.string,
                    text: viewStore.binding(get: { $0.password }, send: Action.typedPassword)
                )
                .textContentType(.password)

                Button {
                    viewStore.send(.tappedLogingButton)
                } label: {
                    LoadingView(.constant(viewStore.isLoadingUser)) {
                        Image(systemName: "terminal")
                        Text(Strings.loginApp.key, bundle: .module)
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
        let email: String
        let password: String
    }

    public enum Action {
        case tappedErrorAlert
        case tappedLogingButton
        case typedEmail(String)
        case typedPassword(String)
    }
}

extension UserLoginViewWatch.StateView {
    public init(
        userState: UserReducer.State
    ) {
        switch userState.status {
        case .logout(let state):
            self.isLoadingUser = state.isLoading
        case .logged:
            self.isLoadingUser = false
        }

        switch userState.route {
        case nil:
            self.errorMessageToDisplayText = nil
        case .some(.error(let error)):
            self.errorMessageToDisplayText = error.localizedDescription
        }

        if let logData = (/UserReducer.State.UserStatus.logout).extract(from: userState.status) {
            self.password = logData.password
            self.email = logData.email
        } else {
            self.password = ""
            self.email = ""
        }
    }
}

extension UserReducer.Action {
    public init(
        userViewAction: UserLoginViewWatch.Action
    ) {
        switch userViewAction {
        case .tappedErrorAlert:
            self = .errorHandled
        case .tappedLogingButton:
            self = .logoutUser(.login)
        case .typedEmail(let email):
            self = .logoutUser(.setEmail(email))
        case .typedPassword(let password):
            self = .logoutUser(.setPassword(password))
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
                        reducer: UserReducer()
                    )
                    .scope(
                        state: UserLoginViewWatch.StateView.init(userState:),
                        action: UserReducer.Action.init(userViewAction:)
                    )
            )
            .previewDisplayName("Login")

            UserLoginViewWatch(
                store:
                    Store(
                        initialState: .empty,
                        reducer: UserReducer()
                    )
                    .scope(
                        state: UserLoginViewWatch.StateView.init(userState:),
                        action: UserReducer.Action.init(userViewAction:)
                    )
            )
            .environment(\.locale, .init(identifier: "fr"))
            .previewDisplayName("Login French")

            UserLoginViewWatch(
                store:
                    Store(
                        initialState: .init(
                            status: .logout(.init(email: "", password: "", isLoading: true)),
                            route: nil
                        ),
                        reducer: UserReducer()
                    )
                    .scope(
                        state: UserLoginViewWatch.StateView.init(userState:),
                        action: UserReducer.Action.init(userViewAction:)
                    )
            )
            .previewDisplayName("Loading")
        }
    }
}
#endif
#endif
