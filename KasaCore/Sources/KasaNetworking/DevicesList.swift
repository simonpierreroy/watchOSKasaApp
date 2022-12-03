//
//  DevicesList.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 6/3/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Foundation
import KasaCore
import Tagged

extension Networking.App {

    static func relayIsOnToRelayState(_ state: RelayIsOn) -> Int {
        guard state.rawValue else {
            return 0
        }
        return 1
    }

    public static func getRelayState(from raw: RawState) throws -> RelayIsOn {
        switch raw.rawValue {
        case 1: return true
        case 0: return false
        default: throw NSError(domain: "Relay State is invalid", code: -1)
        }
    }

    //Shared Types
    public struct IDTtag {}
    public typealias DeviceID = Tagged<Networking.App.IDTtag, String>
    public struct AliasTag {}
    public typealias Alias = Tagged<Networking.App.AliasTag, String>
    public struct RawStateTag {}
    public typealias RawState = Tagged<Networking.App.RawStateTag, Int>

    public struct KasaDevice: Codable {
        public let deviceId: DeviceID
        public let alias: Alias
    }

    public struct KasaDeviceAndSystemInfo {
        public let device: KasaDevice
        public let info: KasaDeviceSystemInfo
    }

    public struct KasaDeviceList: Codable {
        public let deviceList: [KasaDevice]
    }

    public struct KasaChildrenDevice: Codable {
        public let id: Networking.App.DeviceID
        public let alias: Alias
        public let state: RawState
    }

    public struct KasaDeviceSystemInfo: Codable {
        public let alias: Alias
        public let deviceId: DeviceID
        public let children: [KasaChildrenDevice]?
        public let relay_state: RawState?
        public let sw_ver: String
        public let hw_ver: String
        public let model: String
        public let mac: String
        let err_code: Int
    }

    public static func getDevices(token: Token) async throws -> KasaDeviceList {
        let request = Request<[String: String]>(method: .getDeviceList, params: [:])
        return try await performResquest(request: request, queryItems: ["token": token.rawValue])
    }

    public static func getDevicesAndInfo(token: Token) async throws -> KasaDeviceList {
        let request = Request<[String: String]>(method: .getDeviceList, params: [:])
        return try await performResquest(request: request, queryItems: ["token": token.rawValue])
    }

    public static func getDevicesAndSysInfo(token: Token) async throws -> [KasaDeviceAndSystemInfo] {
        let mainDeviceList = try await getDevices(token: token).deviceList
        try Task.checkCancellation()

        return try await withThrowingTaskGroup(of: KasaDeviceAndSystemInfo.self) { group -> [KasaDeviceAndSystemInfo] in

            for device in mainDeviceList {
                group.addTask {
                    let info = try await getDeviceState(token: token, id: device.deviceId)
                    return KasaDeviceAndSystemInfo.init(device: device, info: info)
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
