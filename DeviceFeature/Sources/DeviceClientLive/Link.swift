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
    private static func validChildToggle() -> some ParserPrinter<Substring, Self> {
        ParsePrint {
            StartsWith<Substring>("toggle")
            End()
        }
        .map(.case(Self.toggle))
    }

    fileprivate struct Parser: ParserPrinter {
        fileprivate init() {}

        fileprivate var body: some ParserPrinter<Substring, Device.DeviceChild.Link> {
            OneOf {
                Device.DeviceChild.Link.validChildToggle()
            }
        }
    }
}

extension Device.Link {

    private static func validDeviceToggle() -> some ParserPrinter<Substring, Self> {
        ParsePrint {
            StartsWith<Substring>("toggle")
            End()
        }
        .map(.case(Self.toggle))
    }

    private static func child() -> some ParserPrinter<Substring, Self> {
        ParsePrint {
            StartsWith<Substring>("child/")
            Prefix(1...) { $0.isNumber || $0.isLetter }
                .map(.string).map(.memberwise(Device.ID.init(rawValue:)))
            Skip { "/" }
            Device.DeviceChild.Link.Parser()
            End()
        }
        .map(.case(Self.child))
    }

    fileprivate struct Parser: ParserPrinter {
        fileprivate init() {}

        fileprivate var body: some ParserPrinter<Substring, Device.Link> {
            OneOf {
                Device.Link.validDeviceToggle()
                Device.Link.child()
            }
        }
    }
}

extension DevicesLink {

    private static func validDevicesToggle() -> some ParserPrinter<Substring, Self> {
        ParsePrint {
            StartsWith<Substring>("device/")
            Prefix(1...) { $0.isNumber || $0.isLetter }
                .map(.string).map(.memberwise(Device.ID.init(rawValue:)))
            Skip { "/" }
            Device.Link.Parser()
        }
        .map(.case(Self.device))
    }

    private static func turnOffAllLink() -> some ParserPrinter<Substring, Self> {
        ParsePrint(.case(Self.turnOffAllDevices)) {
            StartsWith<Substring>("turnOffAllDevices")
            End()
        }
    }

    public struct Parser: ParserPrinter {
        public init() {}

        public var body: some ParserPrinter<Substring, DevicesLink> {
            OneOf {
                DevicesLink.validDevicesToggle()
                DevicesLink.turnOffAllLink()
            }
        }
    }
}
