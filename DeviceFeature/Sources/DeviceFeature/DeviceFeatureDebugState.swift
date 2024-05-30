//
//  DeviceDetailFeature.swift
//
//
//  Created by Simon-Pierre Roy on 9/18/20.
//

import Combine
import ComposableArchitecture
import DeviceClient
import Foundation
import KasaCore
import Tagged

#if DEBUG
extension DevicesReducer.State {
    static let emptyNeverLoaded = Self(devices: [], isLoading: .neverLoaded, alert: nil, token: .init("logged"))

    static let emptyWithLink = Self(
        devices: [],
        isLoading: .neverLoaded,
        alert: nil,
        link: .device(Device.debug1.id, .toggle),
        token: .init("logged")
    )
    static let emptyLoading = Self(devices: [], isLoading: .loadingDevices, alert: nil, token: .init("logged"))

    static let oneDeviceLoaded = Self(
        devices: [.init(device: .debug1, sharedToken: .init("logged"))],
        isLoading: .loaded,
        alert: nil,
        token: .init("logged")
    )

    static func multiRoutes(parentError: String?, childError: String?) -> Self {
        Self(
            devices: [
                .init(
                    isLoading: false,
                    destination: childError.map { .alert(.init(title: TextState($0))) },
                    id: .init(rawValue: "1"),
                    name: "1",
                    children: .init(),
                    details: .noRelay(info: .mock),
                    token: .init("logged")
                )
            ],
            isLoading: .loaded,
            alert: parentError.map { .init(title: TextState($0)) },
            link: nil,
            token: .init("logged")
        )
    }

    static func nDeviceLoaded(n: Int, childrenCount: Int = 0, indexFailed: [Int] = []) -> Self {
        var children: [Device.DeviceChild] = []
        var state: Device.State = .status(relay: false, info: .mock)

        if childrenCount >= 1 {
            children = (1...childrenCount)
                .map { Device.DeviceChild(id: "child \($0)", name: "child \($0)", state: true) }
            state = .noRelay(info: .mock)
        }

        return Self(
            devices: (1...n)
                .map {
                    DeviceReducer.State(
                        device: .init(
                            id: "\($0)",
                            name: "Test device number \($0)",
                            children: children,
                            details: indexFailed.contains($0) ? .failed(.init(code: -1, message: "Error")) : state
                        ),
                        sharedToken: .init("logged")
                    )
                },
            isLoading: .loaded,
            alert: nil,
            token: .init("logged")
        )
    }

    static func deviceWithInfo() -> Self {
        Self(
            devices: [
                .init(
                    isLoading: false,
                    destination: .info(.init(info: .mock, deviceName: "Nice Device")),
                    id: .init(rawValue: "1"),
                    name: "Nice Device",
                    children: .init(),
                    details: .noRelay(info: .mock),
                    info: .init(info: .mock, deviceName: "Nice Device"),
                    token: .init("logged")
                )
            ],
            isLoading: .loaded,
            alert: nil,
            link: nil,
            token: .init("logged")
        )
    }
}
#endif
