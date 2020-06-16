//
//  DeviceState.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 6/3/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Foundation
import Combine
import ComposableArchitecture


extension Networking.App {
    
    private struct DeviceStateParam: Encodable {
        let deviceId: String
        let requestData: RawStringJSONContainer = .init(wrapping:
            ["system": ["get_sysinfo": nil]] //"{\"system\":{\"get_sysinfo\":null}}"
        )
    }
    
    private struct DeviceStateResponse: Decodable {
        let responseData: RawStringJSONContainer
    }
    
    static func getDevicesState(token: User.Token, id: DeviceSate.ID) -> Networking.ModelFetcher<DeviceSate.RelayState> {
        return Effect.catching {
            let data = try encoder.encode(
                Request<DeviceStateParam>.init(method: .passthrough, params: .init(deviceId: id.rawValue))
            )
            let endpointQuerry = baseUrl |> Networking.setQuery(items: ["token": token.rawValue])
            
            guard let endpoint = endpointQuerry else {
                throw Networking.ResquestError(errorDescription: "Invalid token")
            }
            
            return URLRequest(url: endpoint)
                |> mut(^\.httpMethod, Networking.HTTP.post.rawValue)
                <> baseRequest
                <> mut(^\.httpBody, data)
            
        }.flatMap { (request: URLRequest) in
            responseToModel(Networking.modelFetcher(urlSession: session, urlResquest: request, decoder: decoder))
        }.tryMap { (reponse: DeviceStateResponse) in
            guard let state = reponse.responseData.wrapping["system"]?["get_sysinfo"]?["relay_state"] else {
                throw  Networking.ResquestError(errorDescription: "Invalid JSON for relay_state")
            }
            
            switch state {
            case .number(let value): return value == 0 ? false : true
            case .bool(let value): return .init(rawValue: value)
            case .array, .null, .object, .string: throw Networking.ResquestError(errorDescription: "Invalid JSON for relay_state")
            }
        }
        .eraseToAnyPublisher()
    }
    
    private struct ChangeDeviceStateParam: Encodable {
        init(deviceId: String, state: DeviceSate.RelayState) {
            self.deviceId = deviceId
            self.requestData = .init(wrapping:
                ["system": ["set_relay_state": ["state": .bool(state.rawValue)]]] //"{\"system\":{\"set_relay_state\":{\"state\":\(boolState)}}}"
            )
        }
        let deviceId: String
        let requestData: RawStringJSONContainer
    }
    
    
    static func changeDevicesState(token: User.Token, id: DeviceSate.ID, state: DeviceSate.RelayState) -> Networking.ModelFetcher<DeviceSate.RelayState> {
        return Effect.catching {
            let data = try encoder.encode(
                Request<ChangeDeviceStateParam>(method: .passthrough, params: .init(deviceId: id.rawValue, state: state))
            )
            let endpointQuerry = baseUrl |> Networking.setQuery(items: ["token": token.rawValue])
            
            guard let endpoint = endpointQuerry else {
                throw Networking.ResquestError(errorDescription: "Invalid token querry items")
            }
            
            return URLRequest(url: endpoint)
                |> mut(^\.httpMethod, Networking.HTTP.post.rawValue)
                <> baseRequest
                <> mut(^\.httpBody, data)
            
        }.flatMap { (request: URLRequest) in
            responseToModel(Networking.modelFetcher(urlSession: session, urlResquest: request, decoder: decoder))
        }.map { (reponse: DeviceStateResponse) in
            return state
        }
        .eraseToAnyPublisher()
    }
    
    static func toggleDevicesState(token: User.Token, id: DeviceSate.ID) ->  Networking.ModelFetcher<DeviceSate.RelayState>  {
        getDevicesState(token: token, id: id)
            .flatMap { state in
                return changeDevicesState(token: token, id: id, state: state.toggle())
        }.eraseToAnyPublisher()
    }
}
