//
//  Loggin.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 6/3/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import ComposableArchitecture
import Foundation
import KasaCore
import KasaNetworking
import UserClient

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
        let refreshToken: String
        let email: String
        let accountId: String
    }

    private struct LoginParam: Encodable {
        let appType: AppType = .iOS
        let cloudUserName: String
        let cloudPassword: String
        let terminalUUID: User.TerminalId
        let refreshTokenNeeded: Bool = true
    }

    static func login(with credential: Credential, terminalUUID: User.TerminalId) async throws -> LoggedUserInfo {

        let requestInfo = RequestInfo<LoginParam>(
            method: .login,
            params: .init(
                cloudUserName: credential.email,
                cloudPassword: credential.password,
                terminalUUID: terminalUUID
            ),
            queryItems: [:],
            httpMethod: .post
        )

        return try await performRequestToModel(requestInfo: requestInfo)
    }
}
