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

#if os(watchOS)
public struct UserLoginViewWatch: View {
    
    public init(store: Store<StateView, Action>) {
        self.store = store
    }
    
    @State var email: String = ""
    @State var password: String = ""
    private let store: Store<StateView, Action>
    
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
                    LoadingView(.constant(viewStore.isLoadingUser)) {
                        Image(systemName: "terminal")
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

public extension UserLoginViewWatch {
    
    struct StateView: Equatable {
        let errorMessageToDisplayText: String?
        let isLoadingUser: Bool
    }
    
    enum Action {
        case tappedErrorAlert
        case tappedLogingButton(email: String, password: String)
    }
}

public extension UserLoginViewWatch.StateView {
    init(userState: UserReducer.State) {
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

public extension UserReducer.Action {
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
                                Store(
                                    initialState: .empty,
                                    reducer: UserReducer()
                                ).scope(
                                    state: UserLoginViewWatch.StateView.init(userState:),
                                    action: UserReducer.Action.init(userViewAction:)
                                )
            ).previewDisplayName("Login")
            
            UserLoginViewWatch(store:
                                Store(
                                    initialState: .empty,
                                    reducer: UserReducer()
                                ).scope(
                                    state: UserLoginViewWatch.StateView.init(userState:),
                                    action: UserReducer.Action.init(userViewAction:)
                                )
            )
            .environment(\.locale, .init(identifier: "fr"))
            .previewDisplayName("Login French")
            
            UserLoginViewWatch(store:
                                Store(
                                    initialState: .init(status: .loading, route: nil),
                                    reducer: UserReducer()
                                ).scope(
                                    state: UserLoginViewWatch.StateView.init(userState:),
                                    action: UserReducer.Action.init(userViewAction:)
                                )
            ).previewDisplayName("Loading")
        }
    }
}
#endif
#endif
