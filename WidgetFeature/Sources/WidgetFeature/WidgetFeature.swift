import Foundation
import WidgetClient
import Combine
import KasaCore
import WidgetKit

public func getCacheState(environment: WidgetEnvironment) throws -> WidgetState {
    let user = environment.loadUser()
    let devices = try environment.loadDevices()
    return WidgetState.init(user: user, device: devices)
}

public func newEntry(
    env: WidgetEnvironment,
    for context: TimelineProviderContext
) -> DataDeviceEntry {
    guard let cache = try? getCacheState(environment: env) else {
        return DataDeviceEntry(date: Date(), userIsLogged: false, devices: [])
    }
    
    if cache.user == nil {
        return DataDeviceEntry(date: Date(), userIsLogged: false, devices: [])
    } else {
        return DataDeviceEntry(date: Date(), userIsLogged: true, devices: cache.device)
    }    
}


