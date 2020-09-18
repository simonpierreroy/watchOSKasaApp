//
//  DevicesList.swift
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
    
    public struct KasaDevice: Codable {
        public let deviceId: String
        public let alias: String
    }
    
    public struct KasaDeviceList: Codable {
        public let deviceList: [KasaDevice]
    }
    
    public static func getDevices(token: Token) -> Networking.ModelFetcher<KasaDeviceList> {
        return Effect.catching {
            let data = try Networking.App.encoder.encode(Request<JSONValue>(method: .getDeviceList, params: [:]))
            let endpointQuerry = baseUrl |> Networking.setQuery(items: ["token": token.rawValue])
            
            guard let endpoint = endpointQuerry else {
                throw Networking.ResquestError(errorDescription: "Invalid endpoint query parameters")
            }
            
            return URLRequest(url: endpoint)
                |> mut(^\.httpMethod, Networking.HTTP.post.rawValue)
                <> baseRequest
                <> mut(^\.httpBody, data)
            
        }.flatMap { (request: URLRequest) in
            responseToModel(Networking.modelFetcher(urlSession: session, urlResquest: request, decoder: decoder))
        }.eraseToAnyPublisher()
    }
}

