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
                            text: viewStore.binding(get: { $0.email }, send: Action.typedEmail)
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
                            text: viewStore.binding(get: { $0.password }, send: Action.typedPassword)
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
                            Text(Strings.loginApp.key, bundle: .module)
                                .foregroundColor(Color.green)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(32)
                }
                .frame(maxWidth: 500).padding()
            }
            .frame(maxWidth: .infinity)
            .disabled(viewStore.isLoadingUser)
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
        let email: String
        let password: String
    }

    public enum Action: Equatable {
        case tappedErrorAlert
        case tappedLogingButton
        case typedEmail(String)
        case typedPassword(String)
    }
}

extension UserLoginViewiOS.StateView {
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
        userViewAction: UserLoginViewiOS.Action
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
            UserLoginViewiOS(
                store:
                    Store(
                        initialState: .empty,
                        reducer: UserReducer()
                    )
                    .scope(
                        state: UserLoginViewiOS.StateView.init(userState:),
                        action: UserReducer.Action.init(userViewAction:)
                    )
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Login")

            UserLoginViewiOS(
                store:
                    Store(
                        initialState: .empty,
                        reducer: UserReducer()
                    )
                    .scope(
                        state: UserLoginViewiOS.StateView.init(userState:),
                        action: UserReducer.Action.init(userViewAction:)
                    )
            )
            .environment(\.locale, .init(identifier: "fr"))
            .previewDisplayName("Login French")

            UserLoginViewiOS(
                store:
                    Store(
                        initialState: .init(
                            status: .logout(.init(email: "", password: "", isLoading: true)),
                            route: nil
                        ),
                        reducer: UserReducer()
                    )
                    .scope(
                        state: UserLoginViewiOS.StateView.init(userState:),
                        action: UserReducer.Action.init(userViewAction:)
                    )
            )
            .previewDisplayName("Loading")
        }
    }
}
#endif
#endif
