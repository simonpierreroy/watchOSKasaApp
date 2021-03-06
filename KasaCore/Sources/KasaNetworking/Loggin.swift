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
import KasaCore

extension Networking.App {
    
    public struct Credential: Codable, Equatable {
        public init(email: String, password: String) {
            self.email = email
            self.password = password
        }
        let email: String
        let password: String
    }
    
    public struct LoggedUserInfo: Codable {
        public let token: String
    }
    
    private struct LoginParam: Encodable {
        let appType = "Kasa_Android"
        let cloudUserName: String
        let cloudPassword: String
        let terminalUUID: UUID
    }
    
    public static func login(cred: Credential) -> Networking.ModelFetcher<LoggedUserInfo> {
        
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
