//
//  SystemImages.swift
//  KasaCore
//
//  Created by Simon-Pierre Roy on 9/20/24.
//

import SwiftUI

public enum SharedSystemImages: String {
    case turnOffAllLights = "moon.zzz.fill"
    case notLogged = "person.crop.circle.badge.exclamationmark"

    public func callAsFunction() -> Image {
        Image(systemName: rawValue)
    }

    public func callAsFunction() -> String {
        self.rawValue
    }
}
