//
//  AppNetworking.swift
//  Networking
//
//  Created by Simon-Pierre Roy on 9/22/19.
//  Copyright © 2019 Wayfair. All rights reserved.
//

import Foundation
import Combine
import ComposableArchitecture

extension Networking {
    
    enum App {
        
        // Shared Info
        static let baseUrl = URL(string: "https://use1-wap.tplinkcloud.com")!
        static let decoder: JSONDecoder = JSONDecoder()
        static let encoder: JSONEncoder = JSONEncoder()
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
        }
        
        struct Request<Param: Encodable>: Encodable {
            let method: EndPoint
            let params: Param
        }
        
        
        typealias FetcherResponse<Model: Decodable> = Networking.ModelFetcher<Response<Model>>
        
        static func responseToModel<Model: Decodable>(_ response: FetcherResponse<Model>) -> Networking.ModelFetcher<Model> {
            return response
                .tryMap { data in
                    guard let result = data.result else {
                        throw Networking.CodeError(statusCode: data.error_code)
                    }
                    return result
                    
            }.eraseToAnyPublisher()
        }
        
        static let baseRequest = guaranteeHeaders
            <> setHeader("Content-Type", "application/json")
    }
}

extension URLComponents {
    static func from(url: URL) -> URLComponents?  {
        URLComponents.init(url: url, resolvingAgainstBaseURL: true)
    }
}
