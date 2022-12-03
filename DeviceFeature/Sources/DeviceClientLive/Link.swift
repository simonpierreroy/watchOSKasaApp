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

    private static let validChildToggleLink = ParsePrint {
        StartsWith<Substring>("toggle")
        End()
    }
    .map(.case(Self.toggle))

    fileprivate static let childLinkParser = OneOf {
        validChildToggleLink
    }
}

extension Device.Link {

    private static let validDeviceToggleLink = ParsePrint {
        StartsWith<Substring>("toggle")
        End()
    }
    .map(.case(Self.toggle))

    private static let childLink = ParsePrint {
        StartsWith<Substring>("child/")
        Prefix(1...) { $0.isNumber || $0.isLetter }
            .map(.string).map(.memberwise(Device.ID.init(rawValue:)))
        Skip { "/" }
        Device.DeviceChild.Link.childLinkParser
        End()
    }
    .map(.case(Self.child))

    fileprivate static let deviceLinkParser = OneOf {
        validDeviceToggleLink
        childLink
    }
}

extension DevicesLink {

    private static let validDevicesToggleLink = ParsePrint {
        StartsWith<Substring>("device/")
        Prefix(1...) { $0.isNumber || $0.isLetter }
            .map(.string).map(.memberwise(Device.ID.init(rawValue:)))
        Skip { "/" }
        Device.Link.deviceLinkParser
    }
    .map(.case(Self.device))

    private static let closeAllLink = ParsePrint(.case(Self.closeAll)) {
        StartsWith<Substring>("closeAll")
        End()
    }

    public static let devicesLinkParser = OneOf {
        validDevicesToggleLink
        closeAllLink
    }
}
