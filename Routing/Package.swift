// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Routing",
    platforms: [.iOS(.v16), .watchOS(.v9)],
    products: [
        .library(
            name: "RoutingClient",
            targets: ["RoutingClient"]
        ),
        .library(
            name: "RoutingClientLive",
            targets: ["RoutingClientLive"]
        ),
    ],
    dependencies: [
        .package(path: "DeviceFeature"),
        .package(path: "KasaCore")
    ],
    targets: [
        .target(
            name: "RoutingClient",
            dependencies: [
                .product(name: "DeviceClient",package: "DeviceFeature"),
                "KasaCore"
            ]),
        .target(
            name: "RoutingClientLive",
            dependencies: [
                .product(name: "DeviceClientLive",package: "DeviceFeature"),
                "RoutingClient",
                "KasaCore"
            ]),
        .testTarget(
            name: "RoutingClientTests",
            dependencies: ["RoutingClient"]
        ),
    ]
)
