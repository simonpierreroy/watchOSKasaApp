//
//  DevicesList.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 6/3/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Foundation
import KasaCore

extension Networking.App {
    
    public struct KasaDevice: Codable {
        public let deviceId: String
        public let alias: String
    }
    
    public struct KasaDeviceList: Codable {
        public let deviceList: [KasaDevice]
    }
    
    public static func getDevices(token: Token) async throws -> KasaDeviceList {
        let request = Request<JSONValue>(method: .getDeviceList,params: [:])
        return try await performResquest(request: request, queryItems: ["token": token.rawValue])
    }
}

