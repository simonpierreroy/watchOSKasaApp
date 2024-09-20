//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 9/26/23.
//

import AppIntents

// This is outside an app, and will not be registered with the system.
public struct EmptyIntent: AppIntent, Sendable {
    public init() {}
    public static let title: LocalizedStringResource = "empty_string"
    static let description = IntentDescription("empty_string")

    public func perform() async throws -> some IntentResult {
        return .result()
    }
}
