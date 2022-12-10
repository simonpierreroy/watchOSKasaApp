//
//  File.swift
//
//
//  Created by Simon-Pierre Roy on 10/5/20.
//

import DeviceClient
import Foundation
import KasaCore
import Parsing

extension Device.DeviceChild.Link {

    private static let validChildToggle = ParsePrint {
        StartsWith<Substring>("toggle")
        End()
    }
    .map(.case(Self.toggle))

    fileprivate static let child = OneOf {
        validChildToggle
    }
}

extension Device.Link {

    private static let validDeviceToggle = ParsePrint {
        StartsWith<Substring>("toggle")
        End()
    }
    .map(.case(Self.toggle))

    private static let child = ParsePrint {
        StartsWith<Substring>("child/")
        Prefix(1...) { $0.isNumber || $0.isLetter }
            .map(.string).map(.memberwise(Device.ID.init(rawValue:)))
        Skip { "/" }
        Device.DeviceChild.Link.child
        End()
    }
    .map(.case(Self.child))

    fileprivate static let device = OneOf {
        validDeviceToggle
        child
    }
}

extension DevicesLink {

    private static let validDevicesToggle = ParsePrint {
        StartsWith<Substring>("device/")
        Prefix(1...) { $0.isNumber || $0.isLetter }
            .map(.string).map(.memberwise(Device.ID.init(rawValue:)))
        Skip { "/" }
        Device.Link.device
    }
    .map(.case(Self.device))

    private static let closeAllLink = ParsePrint(.case(Self.closeAll)) {
        StartsWith<Substring>("closeAll")
        End()
    }

    public static let devices = OneOf {
        validDevicesToggle
        closeAllLink
    }
}
