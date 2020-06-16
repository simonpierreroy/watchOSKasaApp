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


extension Networking.App {
    
    struct KasaDevice: Codable {
        let deviceId: String
        let alias: String
    }
    
    struct KasaDeviceList: Codable {
        let deviceList: [KasaDevice]
    }
    
    static func getDevices(token: User.Token) -> Networking.ModelFetcher<KasaDeviceList> {
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

