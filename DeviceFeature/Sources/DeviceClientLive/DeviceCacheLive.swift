import Combine
import ComposableArchitecture
import DeviceClient
import Foundation
import KasaCore
import KasaNetworking

extension DevicesCache: DependencyKey {
    public static let liveValue = DevicesCache(
        save: save(devices:),
        load: loadCache,
        loadBlocking: loadBlockingCache
    )
}

private let encoder = JSONEncoder()
private let decoder = JSONDecoder()
private let deviceKey: String = "cacheDevices"

@Sendable
private func save(devices: [Device]) async throws {
    let data = try encoder.encode(devices)
    let string = String(data: data, encoding: .utf8)
    UserDefaults.kasaAppGroup.setValue(string, forKeyPath: deviceKey)
}

@Sendable
private func loadBlockingCache() throws -> [Device] {
    guard let stringData = UserDefaults.kasaAppGroup.string(forKey: deviceKey) else {
        return []
    }

    guard let data = stringData.data(using: .utf8) else {
        throw DevicesCache.Failure.dataConversion
    }
    return try decoder.decode([Device].self, from: data)
}

@Sendable
private func loadCache() async throws -> [Device] {
    return try loadBlockingCache()
}
