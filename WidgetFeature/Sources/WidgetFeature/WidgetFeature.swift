import Combine
import Dependencies
import DeviceClient
import Foundation
import IdentifiedCollections
import Intents
import KasaCore
import UserClient
import WidgetClient
import WidgetKit

public struct WidgetDataCache {

    public init(
        loadDevices: @escaping @Sendable () throws -> [Device],
        loadUser: @escaping @Sendable () -> User?

    ) {
        self.loadDevices = loadDevices
        self.loadUser = loadUser

    }
    public let loadDevices: @Sendable () throws -> [Device]
    public let loadUser: @Sendable () -> User?

}

public func getCacheState(cache: WidgetDataCache) throws -> WidgetState {
    let user = cache.loadUser()
    let devices = try cache.loadDevices()
    return WidgetState.init(user: user, device: devices)
}

extension DataDeviceEntry: TimelineEntry {}

public func newEntry(
    cache: WidgetDataCache,
    intentSelection: [FlattenDevice.DoubleID]?,
    for context: TimelineProviderContext
) -> DataDeviceEntry {
    guard let cache = try? getCacheState(cache: cache) else {
        return DataDeviceEntry(date: Date(), userIsLogged: false, devices: [])
    }

    guard cache.user == nil else {
        guard let intentSelection else {
            return DataDeviceEntry(date: Date(), userIsLogged: true, devices: cache.device.flatten())
        }
        let devicesWithId = IdentifiedArray(uniqueElements: cache.device.flatten())
        let foundDevices = intentSelection.compactMap { devicesWithId[id: $0] }
        return DataDeviceEntry(date: Date(), userIsLogged: true, devices: foundDevices)
    }
    return DataDeviceEntry(date: Date(), userIsLogged: false, devices: [])
}
