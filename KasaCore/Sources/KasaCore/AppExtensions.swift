//
//  File.swift
//  
//
//  Created by Simon-Pierre Roy on 10/10/22.
//

import Foundation
import Dependencies
import XCTestDynamicOverlay

extension DependencyValues {
    public var reloadAppExtensions: @Sendable () async -> Void {
        get { self[ReloadAppExtensionsKey.self] }
        set { self[ReloadAppExtensionsKey.self] = newValue }
    }
    
    private enum ReloadAppExtensionsKey: DependencyKey {
        typealias Value = @Sendable () async -> Void
        
        static let liveValue: @Sendable () async -> Void = {
            await MainActor.run {
                liveReloadAppExtensions()
            }
        }
        static let testValue: @Sendable () async -> Void = XCTUnimplemented(
            #"@Dependency(\.reloadAppExtensions)"#
        )
        
        static let previewValue: @Sendable () async -> Void = { }
    }
}


#if canImport(WidgetKit)
import WidgetKit
@Sendable
private func liveReloadAppExtensions () -> Void {
    WidgetCenter.shared.reloadAllTimelines()
}
#else
@Sendable
private func liveReloadAppExtensions () -> Void {
    return
}

#endif
