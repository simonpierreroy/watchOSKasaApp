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

    @State var email: String = ""
    @State var password: String = ""
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
                            text: self.$email
                        )
                        .textContentType(.emailAddress)

                    }
                    .padding()
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)

                    HStack {
                        Image(systemName: "key.icloud")
                            .font(.title2)

                        SecureField(Strings.logPassword.string, text: self.$password)
                            .textContentType(.password)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)

                    Spacer(minLength: 16)

                    Button {
                        viewStore.send(.tappedLogingButton(email: self.email, password: self.password))
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
    }

    public enum Action {
        case tappedErrorAlert
        case tappedLogingButton(email: String, password: String)
    }
}

extension UserLoginViewiOS.StateView {
    public init(
        userState: UserReducer.State
    ) {
        switch userState.status {
        case .loading:
            self.isLoadingUser = true
        case .logout, .logged:
            self.isLoadingUser = false
        }

        switch userState.route {
        case nil:
            self.errorMessageToDisplayText = nil
        case .some(.error(let error)):
            self.errorMessageToDisplayText = error.localizedDescription
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
        case .tappedLogingButton(let email, let password):
            self = .login(.init(email: email, password: password))
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
                        initialState: .init(status: .loading, route: nil),
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
