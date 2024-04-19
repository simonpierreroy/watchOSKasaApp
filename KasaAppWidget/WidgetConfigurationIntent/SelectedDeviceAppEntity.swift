//
//  SelectedDeviceAppEntity.swift
//  Kasa
//
//  Created by Simon-Pierre Roy on 9/18/23.
//  Copyright © 2023 Simon. All rights reserved.
//

import AppIntents
import DeviceClient
import Foundation
import IdentifiedCollections
import WidgetClient
import WidgetClientLive
import WidgetFeature

extension FlattenDevice.ID: EntityIdentifierConvertible {
    public var entityIdentifierString: String {
        self.rawValue
    }

    public static func entityIdentifier(for entityIdentifierString: String) -> DeviceClient.FlattenDevice.ID? {
        .init(rawValue: entityIdentifierString)
    }
}

struct SelectedDeviceAppEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "selected_device_entity_representation"
    static let defaultQuery = SelectedDeviceAppEntityQuery()

    let id: FlattenDevice.ID
    let displayString: String

    init(id: FlattenDevice.ID, displayString: String) {
        self.id = id
        self.displayString = displayString
    }

    init(flattenDevice: FlattenDevice) {
        self.id = flattenDevice.id
        self.displayString = flattenDevice.displayName
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayString)")
    }
}

struct SelectedDeviceAppEntityQuery: EntityQuery {

    let config = ProviderConfig()

    func entities(
        for identifiers: [SelectedDeviceAppEntity.ID]
    ) async throws -> [SelectedDeviceAppEntity] {
        let state = try getWidgetState(from: .init(loadDevices: config.loadDevices, loadUser: config.loadUser))
        let devicesWithId = IdentifiedArray(uniqueElements: state.device.flatten())

        return identifiers.map { id in
            let cachedData = devicesWithId[id: id]
            return .init(id: id, displayString: cachedData?.displayName ?? "N/A")
        }
    }

    func suggestedEntities() async throws -> [SelectedDeviceAppEntity] {
        let state = try getWidgetState(from: .init(loadDevices: config.loadDevices, loadUser: config.loadUser))
        return state.getDevicesIfValidUser().flatten().map(SelectedDeviceAppEntity.init(flattenDevice:))
    }

    func defaultResult() async -> SelectedDeviceAppEntity? {
        nil
    }
}
