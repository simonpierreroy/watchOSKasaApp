//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 4/2/23.
//

import Foundation
import KasaCore
import KasaNetworking
import UserClient

extension Networking.App.Method {
    fileprivate static let refreshToken = Self(endpoint: "refreshToken")
}

extension Networking.App {

    private struct RefreshParam: Encodable {
        let appType: AppType = .iOS
        let terminalUUID: User.TerminalId
        let refreshToken: User.RefreshToken
    }

    private struct RefreshedToken: Codable {
        let token: Token
    }

    static func refreshToken(with refresh: User.RefreshToken, terminalUUID: User.TerminalId) async throws -> Token {

        let requestInfo = RequestInfo<RefreshParam>(
            method: .refreshToken,
            params: .init(
                terminalUUID: terminalUUID,
                refreshToken: refresh
            ),
            queryItems: [:],
            httpMethod: .post
        )

        let response: RefreshedToken = try await performRequestToModel(requestInfo: requestInfo)
        return response.token
    }
}
