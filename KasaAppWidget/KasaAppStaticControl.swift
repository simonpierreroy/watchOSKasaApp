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

struct KasaAppStaticControl: ControlWidget {
    static let kind: String = "KasaAppStaticControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind,
            provider: StaticControlProvider()
        ) { value in
            ControlWidgetButton(action: ToggleAppIntent(flattenDevice: nil)) {
                if value.userIsLogged {
                    Label(WidgetFeature.Strings.turnOff.string, systemImage: SharedSystemImages.turnOffAllLights())
                } else {
                    Label(WidgetFeature.Strings.notLogged.string, systemImage: SharedSystemImages.notLogged())
                }
            }

        }
        .displayName("Kasa Turn Off")
        .description("Toggle lights super fast")
    }

}

struct StaticControlProvider: ControlValueProvider {
    let config = ProviderConfig()
    let previewValue: WidgetClient.DataDeviceEntry = .preview(1)

    func currentValue() async throws -> WidgetClient.DataDeviceEntry {
        return newEntry(
            cache: .init(loadDevices: config.loadDevices, loadUser: config.loadUser),
            intentSelection: nil
        )
    }
}
