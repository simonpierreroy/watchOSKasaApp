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

extension Networking.App {
    
    private struct System<SubSystem: Codable>: Codable {
        let system: SubSystem
    }
    
    private struct SystemInfoDiscover: Codable {}
    
    private struct GetSysInfo<State: Codable>: Codable {
        let get_sysinfo: State
        // encode when nill value
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(get_sysinfo, forKey: .get_sysinfo)
        }
    }
    
    private struct RelayStatePut: Codable {
        let state: Int
    }
    
    private struct RelayStateGet: Codable {
        let err_code: Int
    }
    
    private struct SetRelayState<State: Codable>: Codable {
        let set_relay_state: State
    }
    
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
        let responseData: RawStringJSONContainer<System<GetSysInfo<KasaDeviceSystemInfo>>>
    }
    
    private struct ChangeDeviceStateParam: Encodable {
        
        struct Context: Encodable {
            let child_ids: [String]
        }
        
        init(deviceId: DeviceID, state: RelayIsOn, children: [DeviceID]) {
            self.deviceId = deviceId.rawValue
            self.context = .init(child_ids: children.map(\.rawValue))
            
            self.requestData = .init(
                wrapping: .init(
                    system: .init(set_relay_state: .init(state: relayIsOnToRelayState(state)))
                )
            )
        }
        
        let deviceId: String
        let context: Context
        //Pass to API: "{\"system\":{\"set_relay_state\":{\"state\":\(boolState)}}}"
        let requestData: RawStringJSONContainer<System<SetRelayState<RelayStatePut>>>
    }
    
    private struct ChangeDeviceStateResponse: Decodable {
        let responseData: RawStringJSONContainer<System<SetRelayState<RelayStateGet>>>
    }
}

extension Networking.App {
    
    public static func getDeviceState(
        token: Token,
        id: DeviceID
    ) async throws -> KasaDeviceSystemInfo {
        
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
    
    public static func tryToGetDeviceRelayState(
        token: Token,
        id: DeviceID,
        childId: DeviceID?
    ) async throws -> RelayIsOn {
        let info = try await getDeviceState(token: token, id: id)
        let rawRelayState: RawState?
        
        if let childId = childId  {
            guard let child = info.children?.first(where: { childId == $0.id }) else {
                throw  Networking.ResquestError(errorDescription: "No child matching")
            }
            rawRelayState = child.state
        } else {
            rawRelayState = info.relay_state
        }
        
        guard let relayState =  getRelayState(from: rawRelayState) else {
            throw  Networking.ResquestError(errorDescription: "Device has no relay_state")
        }
        
        return relayState
    }
    
    public static func changeDeviceRelayState(
        token: Token,
        id: DeviceID,
        childId: DeviceID?,
        state: RelayIsOn
    ) async throws -> RelayIsOn {
        
        let children: [DeviceID]
        if let childId = childId { children = [childId] } else { children = [] }
        
        let request = Request<ChangeDeviceStateParam>(
            method: .passthrough,
            params: .init(
                deviceId: id,
                state: state,
                children: children
            )
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
    
    public static func toggleDeviceRelayState(token: Token, id: DeviceID,  childId: DeviceID?)  async throws -> RelayIsOn  {
        let state = try await tryToGetDeviceRelayState(token: token, id: id, childId: childId)
        try Task.checkCancellation()
        return try await changeDeviceRelayState(token: token, id: id, childId: childId, state: state.toggle())
    }
}
