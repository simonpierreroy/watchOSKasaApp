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
        loadUser: @escaping @Sendable () throws -> User?

    ) {
        self.loadDevices = loadDevices
        self.loadUser = loadUser

    }
    public let loadDevices: @Sendable () throws -> [Device]
    public let loadUser: @Sendable () throws -> User?

}

public func getWidgetState(from cache: WidgetDataCache) throws -> WidgetState {
    let user = try cache.loadUser()
    let devices = try cache.loadDevices()
    return WidgetState(user: user, device: devices)
}

extension DataDeviceEntry: TimelineEntry {}

public func newEntry(
    cache: WidgetDataCache,
    intentSelection: [FlattenDevice.ID]?
) -> DataDeviceEntry {
    guard let state = try? getWidgetState(from: cache) else {
        return DataDeviceEntry(date: Date(), userIsLogged: false, devices: [])
    }

    guard state.user != nil else {
        return DataDeviceEntry(date: Date(), userIsLogged: false, devices: [])
    }

    guard let intentSelection else {
        return DataDeviceEntry(date: Date(), userIsLogged: true, devices: state.device.flatten())
    }

    let foundDevices = Device.flattenSearch(devices: state.device, identifiers: intentSelection)
    return DataDeviceEntry(date: Date(), userIsLogged: true, devices: foundDevices)
}
