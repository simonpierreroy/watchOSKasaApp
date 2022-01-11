//
//  DeviceState.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 6/3/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Foundation
import ComposableArchitecture
import KasaCore
import Tagged

extension Networking.App {
    
    private struct DeviceStateParam: Encodable {
        let deviceId: String
        let requestData: RawStringJSONContainer = .init(
            wrapping: ["system": ["get_sysinfo": nil]] //"{\"system\":{\"get_sysinfo\":null}}"
        )
    }
    
    private struct DeviceStateResponse: Decodable {
        let responseData: RawStringJSONContainer
        
        func getRelayState() -> RelayIsOn? {
            guard let state = responseData.wrapping["system"]?["get_sysinfo"]?["relay_state"] else {
                return nil
            }
            
            switch state {
            case .number(let value):
                return value == 0 ? false : true
            case .bool(let value):
                return .init(rawValue: value)
            case .array, .null, .object, .string:
                return nil
            }
        }
        
        func getErrorCodeForSetRelayState() -> Int? {
            guard let errorState = responseData.wrapping["system"]?["set_relay_state"]?["err_code"] else {
                return nil
            }
            
            switch errorState {
            case .number(let value):
                return Int(value)
            case .array, .null, .object, .string, .bool:
                return nil
            }
        }
    }
    
    public typealias DeviceID = Tagged<Networking.App, String>
    
    public static func getDevicesState(
        token: Token,
        id: DeviceID
    ) async throws -> RelayIsOn {
        
        let data = try encoder.encode(
            Request<DeviceStateParam>.init(
                method: .passthrough,
                params: .init(deviceId: id.rawValue)
            )
        )
        
        let endpointQuerry = baseUrl |> Networking.setQuery(items: ["token": token.rawValue])
        
        guard let endpoint = endpointQuerry else {
            throw Networking.ResquestError(errorDescription: "Invalid token")
        }
        
        let request = URLRequest(url: endpoint)
        |> mut(^\.httpMethod, Networking.HTTP.post.rawValue)
        <> baseRequest
        <> mut(^\.httpBody, data)
        
        let response: Response<DeviceStateResponse> = try await Networking.modelFetcher(
            decoder: decoder,
            urlSession: session,
            urlResquest: request
        )
        let deviceStateResponse = try responseToModel(response)
        
        guard let state = deviceStateResponse.getRelayState() else {
            throw Networking.ResquestError(errorDescription: "Invalid JSON for relay_state")
        }
        
        return state
    }
    
    private struct ChangeDeviceStateParam: Encodable {
        init(deviceId: String, state: RelayIsOn) {
            self.deviceId = deviceId
            self.requestData = .init(
                wrapping: ["system": ["set_relay_state": ["state": .bool(state.rawValue)]]] //"{\"system\":{\"set_relay_state\":{\"state\":\(boolState)}}}"
            )
        }
        let deviceId: String
        let requestData: RawStringJSONContainer
    }
    
    
    public static func changeDevicesState(
        token: Token,
        id: DeviceID,
        state: RelayIsOn
    ) async throws -> RelayIsOn {
        
        let data = try encoder.encode(
            Request<ChangeDeviceStateParam>(
                method: .passthrough,
                params: .init(deviceId: id.rawValue, state: state)
            )
        )
        
        let endpointQuerry = baseUrl |> Networking.setQuery(items: ["token": token.rawValue])
        
        guard let endpoint = endpointQuerry else {
            throw Networking.ResquestError(errorDescription: "Invalid token querry items")
        }
        
        let request = URLRequest(url: endpoint)
        |> mut(^\.httpMethod, Networking.HTTP.post.rawValue)
        <> baseRequest
        <> mut(^\.httpBody, data)
        
        let response: Response<DeviceStateResponse> = try await Networking.modelFetcher(
            decoder: decoder,
            urlSession: session,
            urlResquest: request
        )
        
        let deviceStateResponse = try responseToModel(response)
        
        guard let errorCode = deviceStateResponse.getErrorCodeForSetRelayState(),
              errorCode == 0 else {
            throw Networking.ResquestError(errorDescription: "Invalid JSON for set_relay_state")
        }
        
        return state
    }
    
    public static func toggleDevicesState(token: Token, id: DeviceID)  async throws -> RelayIsOn  {
        let state = try await getDevicesState(token: token, id: id)
        return try await changeDevicesState(token: token, id: id, state: state.toggle())
    }
}
