//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 10/10/22.
//

import Dependencies
import Foundation
import WidgetKit
import XCTestDynamicOverlay

extension DependencyValues {
    public var reloadAppExtensions: @Sendable () async -> Void {
        get { self[ReloadAppExtensionsKey.self] }
        set { self[ReloadAppExtensionsKey.self] = newValue }
    }

    public enum ReloadAppExtensionsKey: DependencyKey {
        public typealias Value = @Sendable () async -> Void

        public static let liveValue: Value = {
            await MainActor.run {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }

        public static let testValue: Value = unimplemented(#"@Dependency(\.reloadAppExtensions)"#)
        public static let previewValue: Value = {}
    }
}
