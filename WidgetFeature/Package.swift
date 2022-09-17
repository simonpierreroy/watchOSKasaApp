// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WidgetFeature",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "WidgetFeature",
            targets: ["WidgetFeature"]
        ),
        .library(
            name: "WidgetClient",
            targets: ["WidgetClient"]
        ),
        .library(
            name: "WidgetClientLive",
            targets: ["WidgetClientLive"]
        )
    ],
    dependencies: [
        .package(path: "KasaCore"),
        .package(path: "DeviceFeature"),
        .package(path: "UserFeature"),
        .package(path: "Routing")
    ],
    targets: [
        .target(
            name: "WidgetFeature",
            dependencies: [
                "KasaCore",
                "WidgetClient",
                .product(name: "RoutingClient",package: "Routing"),
            ]),
        .target(
            name: "WidgetClient",
            dependencies: [
                .product(name: "DeviceClient", package: "DeviceFeature"),
                .product(name: "UserClient", package: "UserFeature"),
                .product(name: "RoutingClient",package: "Routing"),
            ]),
        .target(
            name: "WidgetClientLive",
            dependencies: [
                "WidgetClient",
                .product(name: "DeviceClientLive", package: "DeviceFeature"),
                .product(name: "UserClientLive", package: "UserFeature"),
                .product(name: "RoutingClientLive",package: "Routing"),
            ]),
        .testTarget(
            name: "WidgetFeatureTests",
            dependencies: ["WidgetFeature"]
        ),
    ]
)
