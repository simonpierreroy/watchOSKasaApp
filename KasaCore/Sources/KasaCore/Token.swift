//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 9/18/20.
//

import Foundation
import Tagged

public enum APIToken {}
public typealias Token = Tagged<APIToken, String>

public enum AppType: String, Codable {
    case iOS = "Kasa_iOS"
    case android = "Kasa_Android"
}
