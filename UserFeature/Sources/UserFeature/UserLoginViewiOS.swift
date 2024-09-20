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

    public init(store: StoreOf<UserLogoutReducer>) {
        self.store = store
    }

    @Bindable private var store: StoreOf<UserLogoutReducer>

    public var body: some View {
        ScrollView {
            Text(Strings.kasaName.key, bundle: .module).font(.largeTitle)
            SharedSystemImages.toggleALight().font(.largeTitle)
            Spacer(minLength: 32)
            VStack {
                HStack {
                    Image(systemName: "person.icloud")
                        .font(.title2)
                    TextField(
                        Strings.logEmail.string,
                        text: $store.email
                    )
                    .textContentType(.emailAddress)

                }
                .padding()
                .background(Color.orange.opacity(0.2))
                .clipShape(.rect(cornerRadius: 8))

                HStack {
                    Image(systemName: "key.icloud")
                        .font(.title2)

                    SecureField(
                        Strings.logPassword.string,
                        text: $store.password
                    )
                    .textContentType(.password)
                }
                .padding()
                .background(Color.orange.opacity(0.2))
                .clipShape(.rect(cornerRadius: 8))

                Spacer(minLength: 16)

                Button {
                    store.send(.login)
                } label: {
                    LoadingView(store.isLoading) {
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
                .clipShape(.rect(cornerRadius: 32))
            }
            .disabled(store.isLoading)
            .frame(maxWidth: 500).padding()
        }
        .frame(maxWidth: .infinity)
        .alert($store.scope(state: \.alert, action: \.alert))
        .foregroundColor(.orange)
    }
}

#if DEBUG

#Preview("Login") {
    UserLoginViewiOS(
        store:
            Store(
                initialState: .empty,
                reducer: { UserLogoutReducer() }
            )
    )
    .preferredColorScheme(.dark)
}

#Preview("Login Failed") {
    UserLoginViewiOS(
        store:
            Store(
                initialState: .empty,
                reducer: {
                    UserLogoutReducer().dependency(\.userClient, .mockFailed())
                }
            )
    )
    .preferredColorScheme(.dark)
}

#Preview("Login French") {
    UserLoginViewiOS(
        store:
            Store(
                initialState: .empty,
                reducer: { UserLogoutReducer() }
            )
    )
    .environment(\.locale, .init(identifier: "fr"))
}

#Preview("Loading") {
    UserLoginViewiOS(
        store:
            Store(
                initialState: .init(email: "", password: "", isLoading: true),
                reducer: { UserLogoutReducer() }
            )
    )
}
#endif
#endif
