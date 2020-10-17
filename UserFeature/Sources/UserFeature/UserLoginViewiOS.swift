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
import BaseUI

#if os(iOS)
public struct UserLoginViewiOS: View {
    
    public init(store: Store<StateView, Action>) {
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
                            Strings.log_email.string,
                            text: self.$email
                        )
                        .textContentType(.emailAddress)
                        
                    }.padding()
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
                    
                    HStack {
                        Image(systemName: "key.icloud")
                            .font(.title2)
                        
                        SecureField(Strings.log_password.string, text: self.$password)
                            .textContentType(.password)
                    }.padding()
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
                    
                    Spacer(minLength: 16)
                    
                    
                    Button(action: {
                        viewStore.send(.tappedLogingButton(email: self.email, password: self.password))
                    }) {
                        LoadingView(.constant(viewStore.isLoadingUser)) {
                            Text(Strings.login_app.key, bundle: .module)
                                .foregroundColor(Color.green)
                        }.frame(maxWidth: .infinity)
                        .padding()
                    }
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(32)
                }.frame(maxWidth: 500).padding()
            }.frame(maxWidth: .infinity)
            .disabled(viewStore.isLoadingUser)
            .alert(
                item: viewStore.binding(
                    get: { $0.errorMessageToDisplayText.map(AlertInfo.init(title:))},
                    send: .tappedErrorAlert
                ),
                content: { Alert(title: Text($0.title)) }
            )
            
        }.foregroundColor(.orange)
    }
}

extension UserLoginViewiOS {
    struct AlertInfo: Identifiable {
        var title: String
        var id: String { self.title }
    }
}

public extension UserLoginViewiOS {
    
    struct StateView: Equatable {
        let errorMessageToDisplayText: String?
        let isLoadingUser: Bool
    }
    
    enum Action {
        case tappedErrorAlert
        case tappedLogingButton(email: String, password: String)
    }
}

public extension UserLoginViewiOS.StateView {
    init(userState: UserState) {
        self.errorMessageToDisplayText = userState.error?.localizedDescription
        self.isLoadingUser = userState.isLoading
    }
}

public extension UserAction {
    init(userViewAction: UserLoginViewiOS.Action) {
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
            UserLoginViewiOS(store:
                                Store<UserState, UserAction>.init(
                                    initialState:
                                        UserState.init(user: nil, isLoading: false),
                                    reducer: userReducer,
                                    environment: UserEnvironment.mockUserEnv
                                ).scope(
                                    state: UserLoginViewiOS.StateView.init(userState:),
                                    action: UserAction.init(userViewAction:)
                                )
            ).preferredColorScheme(.dark)
            .previewDisplayName("Login")
            
            UserLoginViewiOS(store:
                                Store<UserState, UserAction>.init(
                                    initialState:
                                        UserState.init(user: nil, isLoading: false),
                                    reducer: userReducer,
                                    environment: UserEnvironment.mockUserEnv
                                ).scope(
                                    state: UserLoginViewiOS.StateView.init(userState:),
                                    action: UserAction.init(userViewAction:)
                                )
            )
            .environment(\.locale, .init(identifier: "fr"))
            .previewDisplayName("Login French")
            
            UserLoginViewiOS(store:
                                Store<UserState, UserAction>.init(
                                    initialState:
                                        UserState.init(user: nil, isLoading: true),
                                    reducer: userReducer,
                                    environment: UserEnvironment.mockUserEnv
                                ).scope(
                                    state: UserLoginViewiOS.StateView.init(userState:),
                                    action: UserAction.init(userViewAction:)
                                )
            ).previewDisplayName("Loading")
        }
    }
}
#endif
#endif
