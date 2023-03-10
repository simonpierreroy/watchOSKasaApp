//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 9/18/20.
//

import Foundation
import Tagged

public enum Relay {}
public typealias RelayIsOn = Tagged<Relay, Bool>

extension RelayIsOn {
    public func toggle() -> Self {
        return .init(rawValue: !self.rawValue)
    }
}
