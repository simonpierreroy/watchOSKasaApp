//
//  UserLogin.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 5/30/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct UserLoginView: View {
    
    init(store: Store<UserState, UserAction>) {
        self.store = store
            .scope(
                state: UserLoginView.StateView.init(userState:),
                action: UserAction.init(userViewAction:)
        )
    }
    
    @State var email: String = ""
    @State var password: String = ""
    let store: Store<StateView, Action>
    
    var body: some View {
        WithViewStore(self.store) { viewStore in
            ScrollView {
                Image(systemName: "person.circle")
                    .font(.title)
                    .foregroundColor(Color.orange)
                    .padding()
                
                TextField("Email", text: self.$email)
                    .textContentType(.emailAddress)
                SecureField("Password", text: self.$password)
                    .textContentType(.password)
                
                Button(action: {
                    viewStore.send(.tappedLogingButton(email: self.email, password: self.password))
                }) {
                    HStack {
                        if viewStore.isLoadingUser {
                            Image(systemName: "slowmo")
                        }
                        Text("Login")
                    }
                }
            }
            .disabled(viewStore.isLoadingUser)
            .alert(
                item: viewStore.binding(
                    get: { $0.errorMessageToDisplayText.map(AlertInfo.init(title:))},
                    send: .tappedErrorAlert
                ),
                content: { Alert(title: Text($0.title)) }
            )
            
        }
    }
}

extension UserLoginView {
    struct AlertInfo: Identifiable {
        var title: String
        var id: String { self.title }
    }
}

extension UserLoginView {
    
    struct StateView: Equatable {
        let errorMessageToDisplayText: String?
        let isLoadingUser: Bool
    }
    
    enum Action {
        case tappedErrorAlert
        case tappedLogingButton(email: String, password: String)
    }
}

extension UserLoginView.StateView {
    init(userState: UserState) {
        self.errorMessageToDisplayText = userState.error?.localizedDescription
        self.isLoadingUser = userState.isLoading
    }
}

extension UserAction {
    init(userViewAction: UserLoginView.Action) {
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
            UserLoginView(store:
                .init(
                    initialState:
                    UserState.init(user: nil, isLoading: false),
                    reducer: userReducer,
                    environment: UserEnvironment.mockUserEnv
                )
            ).previewDisplayName("Login")
            
            UserLoginView(store:
                .init(
                    initialState:
                    UserState.init(user: nil, isLoading: true),
                    reducer: userReducer,
                    environment: UserEnvironment.mockUserEnv
                )
            ).previewDisplayName("Loading")
        }
    }
}
#endif
