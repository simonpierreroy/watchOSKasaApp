//
//  Loggin.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 6/3/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Foundation
import Combine
import ComposableArchitecture

extension Networking.App {
    
    struct Credential: Codable, Equatable {
        let email: String
        let password: String
    }
    
    struct LoggedUserInfo: Codable {
        let token: String
    }
    
    private struct LoginParam: Codable {
        let appType = "Kasa_Android"
        let cloudUserName: String
        let cloudPassword: String
        let terminalUUID: UUID
    }
    
    static func login(cred: Credential) -> Networking.ModelFetcher<LoggedUserInfo> {
        
        Effect.catching {
            let params = Request<LoginParam>(
                method: .login,
                params: .init(cloudUserName: cred.email, cloudPassword: cred.password, terminalUUID: .init())
            )
            let data = try Networking.App.encoder.encode(params)
            
            return URLRequest(url: baseUrl)
                |> mut(^\.httpMethod, Networking.HTTP.post.rawValue)
                <> baseRequest
                <> mut(^\.httpBody, data)
            
        }.flatMap { (request: URLRequest) in
            responseToModel(Networking.modelFetcher(urlSession: session, urlResquest: request, decoder: decoder))
        }.eraseToAnyPublisher()
    }
    
}
