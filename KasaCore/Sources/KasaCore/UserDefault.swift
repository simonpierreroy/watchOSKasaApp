//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 10/3/20.
//

import Foundation

extension UserDefaults {
    nonisolated(unsafe) public static let kasaAppGroup = UserDefaults(suiteName: "group.appKasa")!
}
