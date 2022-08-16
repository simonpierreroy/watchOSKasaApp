//
//  File.swift
//  
//
//  Created by Simon-Pierre Roy on 8/16/22.
//

import Foundation
import SwiftUI
import KasaCore

func styleForRelayState(relay: RelayIsOn?) -> (image: String, taint: Color) {
    let imageName: String
    let color: Color
    switch relay {
    case .some(true):
        imageName = "lightbulb.fill"
        color = .yellow
    case .some(false):
        imageName = "lightbulb.slash.fill"
        color = .blue
    default:
        imageName = ""
        color = .gray
    }
    return (imageName,color)
}
