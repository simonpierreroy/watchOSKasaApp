//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 8/16/22.
//

import DeviceClient
import Foundation
import KasaCore
import SwiftUI

func styleFor(relay: RelayIsOn) -> (image: String, tint: Color) {
    guard relay.rawValue else {
        return ("lightbulb.slash.fill", .blue)
    }
    return ("lightbulb.fill", .yellow)
}

func styleFor(details: Device.State) -> (image: String, tint: Color) {
    switch details {
    case .status(let relay, _):
        return styleFor(relay: relay)
    case .noRelay:
        return ("", .gray)
    case .failed:
        return ("wifi.slash", .gray)
    }
}
