//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 9/26/23.
//

import AppIntents

// This is outside an app, and will not be registered with the system.
public struct EmptyIntent: AppIntent {
    public init() {}
    public static var title: LocalizedStringResource = ""
    static var description = IntentDescription("")

    public func perform() async throws -> some IntentResult {
        return .result()
    }
}
