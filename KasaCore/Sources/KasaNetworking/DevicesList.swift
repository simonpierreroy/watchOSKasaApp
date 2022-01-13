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
        if state.rawValue {
            return 1
        } else {
            return 0
        }
    }

    public static func getRelayState(from raw: RawState?) -> RelayIsOn? {
        switch raw?.rawValue {
        case .some(1): return true
        case .some(0): return false
        case .none, .some: return nil
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
        public let model: String
        let err_code: Int
    }
    
    public static func getDevices(token: Token) async throws -> KasaDeviceList {
        let request = Request<JSONValue>(method: .getDeviceList, params: [:])
        return try await performResquest(request: request, queryItems: ["token": token.rawValue])
    }
    
    public static func getDevicesAndInfo(token: Token) async throws -> KasaDeviceList {
        let request = Request<JSONValue>(method: .getDeviceList, params: [:])
        return try await performResquest(request: request, queryItems: ["token": token.rawValue])
    }
    
    public static func getDevicesAndSysInfo(token: Token) async throws -> [KasaDeviceAndSystemInfo] {
        let mainDeviceList = try await getDevices(token: token).deviceList
        
        try Task.checkCancellation()
        var finalList: [KasaDeviceAndSystemInfo] = []
        finalList.reserveCapacity(mainDeviceList.count)
        
        for device in mainDeviceList {
            let info = try await getDeviceState(token: token, id: device.deviceId)
            finalList.append(KasaDeviceAndSystemInfo.init(device: device, info: info))
            try Task.checkCancellation()
        }
        return finalList
    }
}
