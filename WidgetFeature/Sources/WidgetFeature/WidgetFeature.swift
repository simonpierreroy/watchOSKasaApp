import Foundation
import WidgetClient
import Combine
import KasaCore

public func getCacheState(environment: WidgetEnvironment) throws -> WidgetState {
    let user = environment.loadUser()
    let devices = try environment.loadDevices()
    return WidgetState.init(user: user, device: devices)
}


