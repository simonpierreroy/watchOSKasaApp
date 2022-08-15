//
//  File.swift
//  
//
//  Created by Simon-Pierre Roy on 8/15/22.
//

import Foundation

#if DEBUG
public extension URL {
    static let mock = Self(string: "mock")!
}

#endif
