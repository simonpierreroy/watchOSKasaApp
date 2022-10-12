import Foundation
import WidgetClient
import Combine
import KasaCore
import WidgetKit
import Dependencies
import UserClient
import DeviceClient

public struct WidgetDataCache {
    
    public init (
        loadDevices: @escaping @Sendable () throws -> [Device],
        loadUser: @escaping @Sendable () -> User?
        
    ) {
        self.loadDevices = loadDevices
        self.loadUser = loadUser
        
    }
    public let loadDevices:  @Sendable () throws -> [Device]
    public let loadUser: @Sendable () -> User?
    
}

public func getCacheState(cache: WidgetDataCache) throws -> WidgetState {
    let user = cache.loadUser()
    let devices = try cache.loadDevices()
    return WidgetState.init(user: user, device: devices)
}

public func newEntry(
    cache: WidgetDataCache,
    for context: TimelineProviderContext
) -> DataDeviceEntry {
    guard let cache = try? getCacheState(cache: cache) else {
        return DataDeviceEntry(date: Date(), userIsLogged: false, devices: [])
    }
    
    if cache.user == nil {
        return DataDeviceEntry(date: Date(), userIsLogged: false, devices: [])
    } else {
        return DataDeviceEntry(date: Date(), userIsLogged: true, devices: cache.device)
    }    
}


