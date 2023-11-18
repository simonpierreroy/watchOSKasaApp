import Combine
import ComposableArchitecture
import DependenciesMacros
import Foundation
import KasaCore
import Tagged
import XCTestDynamicOverlay

@DependencyClient
public struct DevicesCache: Sendable {
    public enum Failure: Error {
        case dataConversion
    }

    public let save: @Sendable ([Device]) async throws -> Void
    public let load: @Sendable () async throws -> [Device]
    public let loadBlocking: @Sendable () throws -> [Device]

}

extension DevicesCache: TestDependencyKey {
    public static let previewValue = DevicesCache.mock
    public static let testValue = DevicesCache()
}

extension DependencyValues {
    public var devicesCache: DevicesCache {
        get { self[DevicesCache.self] }
        set { self[DevicesCache.self] = newValue }
    }
}

extension DevicesCache {
    public static let mock = Self(
        save: { _ in return },
        load: {
            [
                .debug1,
                .debug2,
                .debug3,
            ]
        },
        loadBlocking: { [.debug1, .debug2, .debug3] }
    )
}
