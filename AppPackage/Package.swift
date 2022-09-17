// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppPackage",
    platforms: [.iOS(.v16), .watchOS(.v9)],
    products: [
        .library(
            name: "AppPackage",
            targets: ["AppPackage"]
        ),
        .library(
            name: "WidgetPackage",
            targets: ["WidgetPackage"]
        ),
    ],
    dependencies: [
        .package(path: "DeviceFeature"),
        .package(path: "UserFeature"),
        .package(path: "Routing"),
        .package(path: "WidgetFeature")
    ],
    targets: [
        .target(
            name: "AppPackage",
            dependencies: [
                "DeviceFeature",
                "UserFeature",
                .product(name: "UserClientLive", package: "UserFeature"),
                .product(name: "DeviceClientLive", package: "DeviceFeature"),
                .product(name: "RoutingClientLive", package: "Routing"),
                .product(name: "RoutingClient",package: "Routing")
            ]),
        .target(
            name: "WidgetPackage",
            dependencies: [
                .product(name: "DeviceClientLive",package: "DeviceFeature"),
                .product(name: "RoutingClientLive",package: "Routing"),
                .product(name: "RoutingClient",package: "Routing"),
                "WidgetFeature",
                .product(name: "WidgetClientLive",package: "WidgetFeature"),
            ]),
        .testTarget(
            name: "AppPackageTests",
            dependencies: ["AppPackage"]
        ),
    ]
)
