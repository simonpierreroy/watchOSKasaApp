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

    public init(store: StoreOf<UserLogoutReducer>) {
        self.store = store
    }

    private let store: StoreOf<UserLogoutReducer>

    public var body: some View {
        WithViewStore(self.store, observe: StateView.init(userLogoutState:)) { viewStore in
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
                        viewStore.send(.login)
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
                    action: \.alert
                )
            )
        }
    }
}

extension UserLoginViewWatch {
    public struct StateView: Equatable {
        let isLoadingUser: Bool
        @BindingViewState var email: String
        @BindingViewState var password: String
        @PresentationState var alert: AlertState<UserLogoutReducer.Action.Alert>?
    }
}

extension UserLoginViewWatch.StateView {
    public init(
        userLogoutState: BindingViewStore<UserLogoutReducer.State>
    ) {
        self.isLoadingUser = userLogoutState.isLoading
        self._password = userLogoutState.$password
        self._email = userLogoutState.$email
        self.alert = userLogoutState.alert
    }
}

#if DEBUG
#Preview("Login") {
    UserLoginViewWatch(
        store: Store(initialState: .empty, reducer: { UserLogoutReducer() })
    )
}

#Preview("Login Failed") {
    UserLoginViewWatch(
        store:
            Store(
                initialState: .empty,
                reducer: { UserLogoutReducer().dependency(\.userClient, .mockFailed()) }
            )
    )
}

#Preview("Login French") {
    UserLoginViewWatch(
        store:
            Store(initialState: .empty, reducer: { UserLogoutReducer() })
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
    )
}
#endif
#endif
