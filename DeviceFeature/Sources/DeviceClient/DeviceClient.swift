import Combine
import ComposableArchitecture
import Foundation
import KasaCore
import Tagged
import XCTestDynamicOverlay

public struct DevicesClient {

    public typealias ToggleEffect = @Sendable (Token, Device.ID, Device.ID?) async throws -> RelayIsOn

    public init(
        loadDevices: @escaping @Sendable (Token) async throws -> [Device],
        toggleDeviceRelayState: @escaping ToggleEffect,
        getDeviceRelayState: @escaping @Sendable (Token, Device.ID, Device.ID?) async throws -> RelayIsOn,
        changeDeviceRelayState: @escaping @Sendable (Token, Device.ID, Device.ID?, RelayIsOn) async throws -> RelayIsOn
    ) {

        self.loadDevices = loadDevices
        self.toggleDeviceRelayState = toggleDeviceRelayState
        self.getDeviceRelayState = getDeviceRelayState
        self.changeDeviceRelayState = changeDeviceRelayState

    }

    public let loadDevices: @Sendable (Token) async throws -> [Device]
    public let toggleDeviceRelayState: ToggleEffect
    public let getDeviceRelayState: @Sendable (Token, Device.ID, Device.ID?) async throws -> RelayIsOn
    public let changeDeviceRelayState: @Sendable (Token, Device.ID, Device.ID?, RelayIsOn) async throws -> RelayIsOn
}

extension DevicesClient: TestDependencyKey {
    public static let testValue = DevicesClient(
        loadDevices: XCTUnimplemented("\(Self.self).loadDevices", placeholder: [.debug1]),
        toggleDeviceRelayState: XCTUnimplemented("\(Self.self).toggleDeviceRelayState", placeholder: true),
        getDeviceRelayState: XCTUnimplemented("\(Self.self).getDeviceRelayState", placeholder: true),
        changeDeviceRelayState: XCTUnimplemented("\(Self.self).changeDeviceRelayState", placeholder: true)
    )

    public static let previewValue = DevicesClient.mock()
}

extension DependencyValues {
    public var devicesClient: DevicesClient {
        get { self[DevicesClient.self] }
        set { self[DevicesClient.self] = newValue }
    }
}

extension DevicesClient {
    public static func mock(waitFor delay: Duration = .seconds(2)) -> Self {
        Self(
            loadDevices: { _ in
                try await taskSleep(for: delay)
                return [
                    .debug1,
                    .debug2,
                    .debug3,
                ]
            },
            toggleDeviceRelayState: { (_, _, _) in
                try await taskSleep(for: delay)
                return .init(rawValue: Bool.random())
            },
            getDeviceRelayState: { (_, _, _) in
                try await taskSleep(for: delay)
                return true
            },
            changeDeviceRelayState: { (_, _, _, state) in
                try await taskSleep(for: delay)
                return state.toggle()
            }
        )
    }
}

#if DEBUG
extension DevicesClient {

    public static func devicesEnvError(
        waitFor delay: Duration = .seconds(2),
        loadError: String,
        toggleError: String,
        getDevicesError: String,
        changeDevicesError: String
    ) -> Self {
        Self(
            loadDevices: { _ in
                try await taskSleep(for: delay)
                throw NSError(domain: loadError, code: 1, userInfo: nil)
            },
            toggleDeviceRelayState: { _, _, _ in
                try await taskSleep(for: delay)
                throw NSError(domain: toggleError, code: 2, userInfo: nil)
            },
            getDeviceRelayState: { _, _, _ in
                try await taskSleep(for: delay)
                throw NSError(domain: getDevicesError, code: 3, userInfo: nil)
            },
            changeDeviceRelayState: { _, _, _, _ in
                try await taskSleep(for: delay)
                throw NSError(domain: changeDevicesError, code: 4, userInfo: nil)
            }
        )
    }
}
#endif
