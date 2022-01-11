//
//  AppNetworking.swift
//  Networking
//
//  Created by Simon-Pierre Roy on 9/22/19.
//  Copyright © 2019 Wayfair. All rights reserved.
//

import Foundation
import ComposableArchitecture
import KasaCore

extension Networking {
    
    public enum App {
        
        static let baseUrl = URL(string: "https://use1-wap.tplinkcloud.com")!
        static let decoder = JSONDecoder()
        static let encoder = JSONEncoder()
        static let session = URLSession(configuration: .default)
        
        struct Response<Model: Decodable>: Decodable {
            let error_code: Int
            let msg: String?
            let result: Model?
        }
        
        enum EndPoint: String, Encodable {
            case passthrough
            case getDeviceList
            case login
            
            func httpMethod() -> Networking.HTTP {
                switch self {
                case .login, .passthrough, .getDeviceList:
                    return .post
                }
            }
        }
        
        struct Request<Param: Encodable>: Encodable {
            let method: EndPoint
            let params: Param
        }
        
        static func responseToModel<Model: Decodable>(_ response: Response<Model>) throws -> Model {
            guard let result = response.result else {
                throw Networking.CodeError(statusCode: response.error_code)
            }
            return result
        }
        
        static let baseRequest = guaranteeHeaders
            <> setHeader("Content-Type", "application/json")
        
        static func performResquest<ModelRequest: Encodable, ModelForResponse: Decodable>(
            request: Request<ModelRequest>,
            queryItems: [String: String]
        ) async throws -> ModelForResponse  {
            
            let data = try Networking.App.encoder.encode(request)
            let endpointQuerry = baseUrl |> Networking.setQuery(items: queryItems)
            
            guard let endpoint = endpointQuerry else {
                throw Networking.ResquestError(errorDescription: "Invalid endpoint query items")
            }
            
            let request = URLRequest(url: endpoint)
            |> mut(^\.httpMethod, request.method.httpMethod().rawValue)
            <> baseRequest
            <> mut(^\.httpBody, data)
            
            let response: Response<ModelForResponse> = try await Networking.modelFetcher(
                decoder: decoder,
                urlSession: session,
                urlResquest: request
            )
            
            return try responseToModel(response)
        }
    }
}

extension URLComponents {
    static func from(url: URL) -> URLComponents?  {
        URLComponents.init(url: url, resolvingAgainstBaseURL: true)
    }
}
