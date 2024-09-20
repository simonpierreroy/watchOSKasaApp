//
//  KasaAppStaticControl.swift
//  KasaAppWidgetExtension
//
//  Created by Simon-Pierre Roy on 9/20/24.
//  Copyright © 2024 Simon. All rights reserved.
//

import BaseUI
import SwiftUI
import WidgetClient
import WidgetClientLive
import WidgetFeature
import WidgetKit

struct KasaAppWithAppIntentControl: ControlWidget {
    static let kind: String = "KasaAppWithAppIntentControl"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: AppIntentControlProvider()
        ) { value in
            ControlWidgetButton(action: ToggleAppIntent(flattenDevice: value.devices.first)) {
                if value.userIsLogged {
                    if let device = value.devices.first {
                        Label(device.displayName, systemImage: SharedSystemImages.toggleALight())
                    } else {
                        Label(
                            WidgetFeature.Strings.noDeviceSelected.string,
                            systemImage: SharedSystemImages.selectDevices()
                        )
                    }
                } else {
                    Label(WidgetFeature.Strings.notLogged.string, systemImage: SharedSystemImages.notLogged())
                }
            }
        }.promptsForUserConfiguration()
            .displayName("Kasa Device")
            .description("Toggle lights super fast")
    }

}

struct AppIntentControlProvider: AppIntentControlValueProvider {
    let config = ProviderConfig()

    func previewValue(configuration: SelectDevicesControlConfigurationIntent) -> DataDeviceEntry {
        return .preview(1)
    }

    func currentValue(configuration: SelectDevicesControlConfigurationIntent) async throws -> DataDeviceEntry {
        let selectionId = configuration.selectedDevice?.id
        let intentSelection = selectionId.flatMap { [$0] } ?? []
        let entry = newEntry(
            cache: .init(loadDevices: config.loadDevices, loadUser: config.loadUser),
            intentSelection: intentSelection
        )
        return entry
    }
}
