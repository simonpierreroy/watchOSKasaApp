//
//  DeviceState.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 6/3/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import ComposableArchitecture
import DeviceClient
import Foundation
import KasaCore
import KasaNetworking

extension Token {
    func queryItem() -> [String: String] {
        return ["token": self.rawValue]
    }
}

extension Networking.App.Method {
    fileprivate static let passthrough = Self(endpoint: "passthrough")
}

extension Networking.App {

    private struct System<SubSystem: Codable>: Codable {
        struct Context: Codable {

            enum CodingKeys: String, CodingKey {
                case childIDs = "child_ids"
            }

            let childIDs: [String]
        }

        init(
            system: SubSystem,
            context: Context? = nil
        ) {
            self.system = system
            self.context = context
        }

        let system: SubSystem
        let context: Context?

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(system, forKey: .system)
            // Only Encode none empty context
            if let context = context, context.childIDs.count > 0 {
                try container.encode(context, forKey: .context)
            }
        }
    }

    private struct SystemInfoDiscover: Codable {}

    private struct GetSysInfo<State: Codable>: Codable {

        enum CodingKeys: String, CodingKey {
            case info = "get_sysinfo"
        }

        let info: State
        // encode when nill value
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(info, forKey: .info)
        }
    }

    private struct RelayStatePut: Codable {
        let state: Int
    }

    private struct RelayStateGet: Codable {
        enum CodingKeys: String, CodingKey {
            case errorCode = "err_code"
        }
        let errorCode: Int
    }

    private struct SetRelayState<State: Codable>: Codable {
        enum CodingKeys: String, CodingKey {
            case state = "set_relay_state"
        }
        let state: State
    }

    private struct DeviceStateParam: Encodable {

        let deviceId: String
        //Pass to API: "{\"system\":{\"get_sysinfo\":null}}"
        let requestData = RawStringJSONContainer(
            wrapping: System(
                system: GetSysInfo<SystemInfoDiscover?>(info: nil)
            )
        )
    }

    private struct DeviceStateResponse: Decodable {
        let responseData: RawStringJSONContainer<System<GetSysInfo<KasaDeviceSystemInfo>>>
    }

    private struct ChangeDeviceStateParam: Encodable {

        init(
            deviceId: DeviceID,
            state: RelayIsOn,
            children: [DeviceID]
        ) {
            self.deviceId = deviceId.rawValue

            self.requestData = .init(
                wrapping: .init(
                    system: .init(state: .init(state: relayIsOnToRelayState(state))),
                    context: .init(childIDs: .init(children.map(\.rawValue)))
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
}

extension Networking.App {

    static func getDeviceState(
        token: Token,
        id: DeviceID
    ) async throws -> KasaDeviceSystemInfo {

        let request = RequestInfo<DeviceStateParam>
            .init(
                method: .passthrough,
                params: .init(deviceId: id.rawValue),
                queryItems: token.queryItem(),
                httpMethod: .post
            )

        let deviceStateResponse: DeviceStateResponse = try await performResquestToModel(
            requestInfo: request
        )

        return deviceStateResponse.responseData.wrapping.system.info
    }

    static func getDeviceStateAPIResponse(
        token: Token,
        id: DeviceID
    ) async throws -> APIResponse<KasaDeviceSystemInfo> {

        let request = RequestInfo<DeviceStateParam>
            .init(
                method: .passthrough,
                params: .init(deviceId: id.rawValue),
                queryItems: token.queryItem(),
                httpMethod: .post
            )

        let deviceStateResponse: APIResponse<DeviceStateResponse> = try await performResquestToAPIResponse(
            requestInfo: request
        )

        return deviceStateResponse.map(\.responseData.wrapping.system.info)
    }

    static func tryToGetDeviceRelayState(
        token: Token,
        id: DeviceID,
        childId: DeviceID?
    ) async throws -> RelayIsOn {
        let info = try await getDeviceState(token: token, id: id)
        let rawRelayState: RawState?

        if let childId = childId {
            guard let child = info.children?.first(where: { childId == $0.id }) else {
                throw Networking.ResquestError(errorDescription: "No child matching")
            }
            rawRelayState = child.state
        } else {
            rawRelayState = info.relayState
        }

        guard let rawRelayState = rawRelayState else {
            throw Networking.ResquestError(errorDescription: "Device has no relay_state")
        }

        return try getRelayState(from: rawRelayState)
    }

    static func changeDeviceRelayState(
        token: Token,
        id: DeviceID,
        childId: DeviceID?,
        state: RelayIsOn
    ) async throws -> RelayIsOn {

        let children: [DeviceID]
        if let childId = childId { children = [childId] } else { children = [] }

        let request = RequestInfo<ChangeDeviceStateParam>(
            method: .passthrough,
            params: .init(
                deviceId: id,
                state: state,
                children: children
            ),
            queryItems: token.queryItem(),
            httpMethod: .post
        )

        let deviceStateResponse: ChangeDeviceStateResponse = try await performResquestToModel(
            requestInfo: request
        )

        guard deviceStateResponse.responseData.wrapping.system.state.errorCode == 0 else {
            throw Networking.ResquestError(errorDescription: "Invalid JSON for set_relay_state")
        }

        return state
    }

    static func toggleDeviceRelayState(token: Token, id: DeviceID, childId: DeviceID?) async throws -> RelayIsOn {
        let state = try await tryToGetDeviceRelayState(token: token, id: id, childId: childId)
        try Task.checkCancellation()
        return try await changeDeviceRelayState(token: token, id: id, childId: childId, state: state.toggle())
    }
}
