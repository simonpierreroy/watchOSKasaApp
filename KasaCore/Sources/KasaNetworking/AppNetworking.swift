//
//  AppNetworking.swift
//  Networking
//
//  Created by Simon-Pierre Roy on 9/22/19.
//  Copyright © 2019 Wayfair. All rights reserved.
//

import ComposableArchitecture
import Foundation
import KasaCore

extension Token {
    public func queryItem() -> [String: String] {
        return ["token": self.rawValue]
    }
}

extension Networking {

    public enum App {

        private static let baseUrl = URL(string: "https://use1-wap.tplinkcloud.com")!
        private static let decoder = JSONDecoder()
        private static let encoder = JSONEncoder()
        private static let session = URLSession(configuration: .default)

        public struct ResponseError: Error {
            public let code: Int
            public let message: String
        }

        public typealias APIResponse<Model> = Result<Model, ResponseError>

        private struct Response<Model: Decodable>: Decodable {
            enum CodingKeys: String, CodingKey {
                case errorCode = "error_code"
                case message = "msg"
                case result
            }
            let errorCode: Int
            let message: String?
            let result: Model?
        }

        public struct Method: Hashable {
            public init(
                endpoint: String
            ) {
                self.endpoint = endpoint
            }
            let endpoint: String
        }

        public struct RequestInfo<Param: Encodable> {
            public init(
                method: Method,
                params: Param,
                queryItems: [String: String],
                httpMethod: Networking.HTTP
            ) {
                self.method = method
                self.params = params
                self.queryItems = queryItems
                self.httpMethod = httpMethod
            }

            public let method: Method
            public let params: Param
            public let queryItems: [String: String]
            public let httpMethod: Networking.HTTP

            fileprivate func getRequest() -> Request<Param> {
                return .init(method: self.method.endpoint, params: self.params)
            }
        }

        fileprivate struct Request<Param: Encodable>: Encodable {
            public init(
                method: String,
                params: Param
            ) {
                self.method = method
                self.params = params
            }
            public let method: String
            public let params: Param
        }

        private static func responseToModel<Model: Decodable>(_ response: Response<Model>) throws -> Model {
            guard let result = response.result else {
                throw Networking.CodeError(statusCode: response.errorCode)
            }
            return result
        }

        private static func responseToAPIResponse<Model: Decodable>(_ response: Response<Model>) -> APIResponse<Model> {
            guard let result = response.result else {
                return .failure(.init(code: response.errorCode, message: response.message ?? ""))
            }
            return .success(result)
        }

        private static let baseRequest =
            guaranteeHeaders
            <> setHeader("Content-Type", "application/json")

        private static func performResquest<ModelRequest: Encodable, ModelForResponse: Decodable>(
            requestInfo: RequestInfo<ModelRequest>
        ) async throws -> Response<ModelForResponse> {

            let data = try Networking.App.encoder.encode(requestInfo.getRequest())
            let endpointQuerry = baseUrl |> Networking.setQuery(items: requestInfo.queryItems)

            guard let endpoint = endpointQuerry else {
                throw Networking.ResquestError(errorDescription: "Invalid endpoint query items")
            }

            let request =
                URLRequest(url: endpoint)
                |> mut(^\.httpMethod, requestInfo.httpMethod.rawValue)
                <> baseRequest
                <> mut(^\.httpBody, data)

            let response: Response<ModelForResponse> = try await Networking.modelFetcher(
                decoder: decoder,
                urlSession: session,
                urlResquest: request
            )

            return response
        }

        public static func performResquestToModel<ModelRequest: Encodable, ModelForResponse: Decodable>(
            requestInfo: RequestInfo<ModelRequest>
        ) async throws -> ModelForResponse {
            let response: Response<ModelForResponse> = try await performResquest(
                requestInfo: requestInfo
            )
            return try responseToModel(response)
        }

        public static func performResquestToAPIResponse<ModelRequest: Encodable, ModelForResponse: Decodable>(
            requestInfo: RequestInfo<ModelRequest>
        ) async throws -> APIResponse<ModelForResponse> {
            let response: Response<ModelForResponse> = try await performResquest(
                requestInfo: requestInfo
            )
            return responseToAPIResponse(response)
        }
    }
}
