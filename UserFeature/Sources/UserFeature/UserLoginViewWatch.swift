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
import UserClient

#if os(watchOS)
public struct UserLoginViewWatch: View {
    
    public init(store: Store<UserState, UserAction>) {
        self.store = store
            .scope(
                state: UserLoginViewWatch.StateView.init(userState:),
                action: UserAction.init(userViewAction:)
            )
    }
    
    @State var email: String = ""
    @State var password: String = ""
    let store: Store<StateView, Action>
    
    public var body: some View {
        WithViewStore(self.store) { viewStore in
            ScrollView {
                Image(systemName: "person.circle")
                    .font(.title)
                    .foregroundColor(Color.orange)
                    .padding()
                
                TextField(
                    Strings.log_email.string,
                    text: self.$email
                )
                .textContentType(.emailAddress)
                SecureField(Strings.log_password.string, text: self.$password)
                    .textContentType(.password)
                
                Button(action: {
                    viewStore.send(.tappedLogingButton(email: self.email, password: self.password))
                }) {
                    HStack {
                        if viewStore.isLoadingUser {
                            Image(systemName: "slowmo")
                        }
                        Text(Strings.login_app.key, bundle: .module)
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

extension UserLoginViewWatch {
    struct AlertInfo: Identifiable {
        var title: String
        var id: String { self.title }
    }
}

extension UserLoginViewWatch {
    
    struct StateView: Equatable {
        let errorMessageToDisplayText: String?
        let isLoadingUser: Bool
    }
    
    enum Action {
        case tappedErrorAlert
        case tappedLogingButton(email: String, password: String)
    }
}

extension UserLoginViewWatch.StateView {
    init(userState: UserState) {
        self.errorMessageToDisplayText = userState.error?.localizedDescription
        self.isLoadingUser = userState.isLoading
    }
}

extension UserAction {
    init(userViewAction: UserLoginViewWatch.Action) {
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
            UserLoginViewWatch(store:
                            .init(
                                initialState:
                                    UserState.init(user: nil, isLoading: false),
                                reducer: userReducer,
                                environment: UserEnvironment.mockUserEnv
                            )
            ).previewDisplayName("Login")
            
            UserLoginViewWatch(store:
                            .init(
                                initialState:
                                    UserState.init(user: nil, isLoading: false),
                                reducer: userReducer,
                                environment: UserEnvironment.mockUserEnv
                            )
            )
            .environment(\.locale, .init(identifier: "fr"))
            .previewDisplayName("Login French")
            
            UserLoginViewWatch(store:
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
#endif
