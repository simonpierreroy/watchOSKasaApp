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
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Selected Device"
    static var defaultQuery = SelectedDeviceAppEntityQuery()

    let id: FlattenDevice.ID
    let displayString: String

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
        return state.getDevicesIfValidUser().flatten()
            .map {
                SelectedDeviceAppEntity(
                    id: $0.id,
                    displayString: $0.displayName
                )
            }
    }

    func defaultResult() async -> SelectedDeviceAppEntity? {
        nil
    }
}
