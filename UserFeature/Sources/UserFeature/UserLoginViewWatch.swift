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

    @Bindable private var store: StoreOf<UserLogoutReducer>

    public var body: some View {
        ScrollView {
            Image(systemName: "person.circle")
                .font(.title)
                .foregroundColor(Color.orange)
                .padding()

            Group {
                TextField(
                    Strings.logEmail.string,
                    text: $store.email
                )
                .textContentType(.emailAddress)
                SecureField(
                    Strings.logPassword.string,
                    text: $store.password
                )
                .textContentType(.password)

                Button {
                    store.send(.login)
                } label: {
                    LoadingView(store.isLoading) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text(Strings.loginApp.key, bundle: .module)
                        }
                    }
                }
            }
            .disabled(store.isLoading)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
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
