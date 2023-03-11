//
//  Loggin.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 6/3/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import ComposableArchitecture
import Foundation
import KasaNetworking

extension Networking.App.Method {
    fileprivate static let login = Self(endpoint: "login")
}

extension Networking.App {

    struct Credential: Codable, Equatable {
        let email: String
        let password: String
    }

    struct LoggedUserInfo: Codable {
        let token: String
    }

    private struct LoginParam: Encodable {
        let appType = "Kasa_Android"
        let cloudUserName: String
        let cloudPassword: String
        let terminalUUID: UUID
    }

    static func login(with credential: Credential) async throws -> LoggedUserInfo {

        let requestInfo = RequestInfo<LoginParam>(
            method: .login,
            params: .init(
                cloudUserName: credential.email,
                cloudPassword: credential.password,
                terminalUUID: .init()
            ),
            queryItems: [:],
            httpMethod: .post
        )

        return try await performRequestToModel(requestInfo: requestInfo)
    }
}
