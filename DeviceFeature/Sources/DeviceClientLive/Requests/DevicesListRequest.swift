//
//  DevicesList.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 6/3/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import DeviceClient
import Foundation
import KasaCore
import KasaNetworking
import Tagged

extension Networking.App.Method {
    fileprivate static let getDeviceList = Self(endpoint: "getDeviceList")
}

extension Networking.App {

    static func relayIsOnToRelayState(_ state: RelayIsOn) -> Int {
        guard state.rawValue else {
            return 0
        }
        return 1
    }

    static func getRelayState(from raw: RawState) throws -> RelayIsOn {
        switch raw.rawValue {
        case 1: return true
        case 0: return false
        default: throw NSError(domain: "Relay State is invalid", code: -1)
        }
    }

    //Shared Types
    struct IDTag {}
    typealias DeviceID = Tagged<Self.IDTag, String>
    struct AliasTag {}
    typealias Alias = Tagged<Self.AliasTag, String>
    struct RawStateTag {}
    typealias RawState = Tagged<Self.RawStateTag, Int>

    struct KasaDevice: Codable {
        let deviceId: DeviceID
        let alias: Alias
    }

    struct KasaDeviceAndSystemInfo {
        let device: KasaDevice
        let info: APIResponse<KasaDeviceSystemInfo>
    }

    struct KasaDeviceList: Codable {
        let deviceList: [KasaDevice]
    }

    struct KasaChildrenDevice: Codable {
        let id: Networking.App.DeviceID
        let alias: Alias
        let state: RawState
    }

    struct KasaDeviceSystemInfo: Codable {

        enum CodingKeys: String, CodingKey {
            case alias
            case deviceId
            case children
            case relayState = "relay_state"
            case softwareVersion = "sw_ver"
            case hardwareVersion = "hw_ver"
            case model
            case mac
            case errorCode = "err_code"
        }

        let alias: Alias
        let deviceId: DeviceID
        let children: [KasaChildrenDevice]?
        let relayState: RawState?
        let softwareVersion: String
        let hardwareVersion: String
        let model: String
        let mac: String
        let errorCode: Int
    }

    static func getDevices(token: Token) async throws -> KasaDeviceList {
        let request = RequestInfo<[String: String]>(
            method: .getDeviceList,
            params: [:],
            queryItems: token.queryItem(),
            httpMethod: .post
        )
        return try await performRequestToModel(requestInfo: request)
    }

    static func getDevicesAndInfo(token: Token) async throws -> KasaDeviceList {
        let request = RequestInfo<[String: String]>(
            method: .getDeviceList,
            params: [:],
            queryItems: token.queryItem(),
            httpMethod: .post
        )
        return try await performRequestToModel(requestInfo: request)
    }

    static func getDevicesAndSysInfo(token: Token) async throws -> [KasaDeviceAndSystemInfo] {
        let mainDeviceList = try await getDevices(token: token).deviceList
        try Task.checkCancellation()

        return try await withThrowingTaskGroup(of: KasaDeviceAndSystemInfo.self) { group -> [KasaDeviceAndSystemInfo] in

            for device in mainDeviceList {
                group.addTask {
                    let info = try await getDeviceStateAPIResponse(token: token, id: device.deviceId)
                    return KasaDeviceAndSystemInfo(device: device, info: info)
                }
            }

            var finalList: [KasaDeviceAndSystemInfo] = []
            finalList.reserveCapacity(mainDeviceList.count)

            for try await infoInGroup in group {
                finalList.append(infoInGroup)
            }

            return finalList.sorted { $0.device.alias < $1.device.alias }
        }
    }
}
