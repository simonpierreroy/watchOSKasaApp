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

protocol SubSystem: Codable {}

struct System<SubSys: Codable>: Codable {
    let system: SubSys
}

public struct SystemInfo: Codable {
     let sw_ver: String
     let model: String
     let alias: String
     let deviceId: String
     let relay_state: Int
     let err_code: Int
    
    public func getRelayState() -> RelayIsOn {
        let stateBool = (relay_state == 1 ? true : false)
        return .init(rawValue: stateBool)
    }
 }

struct SystemInfoDiscover: Codable {}

struct GetSysInfo<State: Codable>: SubSystem {
    let get_sysinfo: State
    
    // encode nill
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(get_sysinfo, forKey: .get_sysinfo)
    }
}

struct RelayStatePut: Codable {
    let state: Int
}

struct RelayStateGet: Codable {
    let err_code: Int
}

struct SetRelayState<State: Codable>: SubSystem {
    let set_relay_state: State
}

extension Networking.App {
        
    private struct DeviceStateParam: Encodable {
        
        let deviceId: String
        //Pass to API: "{\"system\":{\"get_sysinfo\":null}}"
        let requestData =  RawStringJSONContainer(
            wrapping: System(
                system: GetSysInfo<SystemInfoDiscover?>(get_sysinfo: nil)
            )
        )
    }
    
    private struct DeviceStateResponse: Decodable {
        let responseData: RawStringJSONContainer<System<GetSysInfo<SystemInfo>>>
    }
    
    public typealias DeviceID = Tagged<Networking.App, String>
    
    public static func getDeviceState(
        token: Token,
        id: DeviceID
    ) async throws -> SystemInfo {
        
        let request = Request<DeviceStateParam>.init(
            method: .passthrough,
            params: .init(deviceId: id.rawValue)
        )
        
        let deviceStateResponse: DeviceStateResponse = try await performResquest(
            request: request,
            queryItems:  ["token": token.rawValue]
        )
                
        return deviceStateResponse.responseData.wrapping.system.get_sysinfo
    }
        
    private struct ChangeDeviceStateParam: Encodable {
        
        init(deviceId: String, state: RelayIsOn) {
            self.deviceId = deviceId
            self.requestData = .init(
                wrapping: .init(
                    system: .init(set_relay_state: .init(state: state.rawValue ? 1 : 0))
                )
            )
        }

        let deviceId: String
        //Pass to API: "{\"system\":{\"set_relay_state\":{\"state\":\(boolState)}}}"
        let requestData: RawStringJSONContainer<System<SetRelayState<RelayStatePut>>>
    }
    
    private struct ChangeDeviceStateResponse: Decodable {
        let responseData: RawStringJSONContainer<System<SetRelayState<RelayStateGet>>>
    }
    
    
    public static func changeDeviceRelayState(
        token: Token,
        id: DeviceID,
        state: RelayIsOn
    ) async throws -> RelayIsOn {
        
        let request = Request<ChangeDeviceStateParam>(
            method: .passthrough,
            params: .init(deviceId: id.rawValue, state: state)
        )
        
        let deviceStateResponse: ChangeDeviceStateResponse = try await performResquest(
            request: request,
            queryItems:  ["token": token.rawValue]
        )
        
        guard deviceStateResponse.responseData.wrapping.system.set_relay_state.err_code == 0 else {
            throw Networking.ResquestError(errorDescription: "Invalid JSON for set_relay_state")
        }
        
        return state
    }
    
    public static func toggleDeviceRelayState(token: Token, id: DeviceID)  async throws -> RelayIsOn  {
        let state = try await getDeviceState(token: token, id: id).getRelayState()
        return try await changeDeviceRelayState(
            token: token, id: id,
            state: state.toggle()
        )
    }
}
