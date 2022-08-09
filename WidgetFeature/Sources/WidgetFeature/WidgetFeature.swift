import Foundation
import WidgetClient
import Combine
import KasaCore

public func getCacheState(environment: WidgetEnvironment) async throws -> WidgetState {
    async let user = environment.loadUser()
    async let devices = environment.loadDevices()
    return try await WidgetState.init(user: user, device: devices)
}


