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

struct StateImageView: View {

    static func styleFor(relay: RelayIsOn) -> (image: String, tint: Color) {
        guard relay.rawValue else {
            return ("lightbulb.fill", .blue)
        }
        return ("lightbulb.max.fill", .yellow)
    }

    static func styleFor(details: Device.State) -> (image: String, tint: Color) {
        switch details {
        case .status(let relay, _): styleFor(relay: relay)
        case .noRelay: ("", .gray)
        case .failed: ("wifi.slash", .gray)
        }
    }

    init(details: Device.State, isActive: Bool) {
        self.state = Self.styleFor(details: details)
        self.isActive = isActive
    }

    init(relay: RelayIsOn, isActive: Bool) {
        self.state = Self.styleFor(relay: relay)
        self.isActive = isActive
    }

    init(state: (image: String, tint: Color), isActive: Bool) {
        self.state = state
        self.isActive = isActive
    }

    let state: (image: String, tint: Color)
    let isActive: Bool

    var body: some View {
        Image(systemName: state.image)
            .font(.title3)
            .foregroundColor(state.tint)
            .symbolEffect(.pulse, isActive: isActive)
            .contentTransition(
                .symbolEffect(.replace)
            )
    }
}
