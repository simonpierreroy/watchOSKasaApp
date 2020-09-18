// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DeviceFeature",
    platforms: [.iOS(.v13), .watchOS(.v6)],
    products: [
        .library(
            name: "DeviceClient",
            targets: ["DeviceClient"]),
        .library(
            name: "DeviceClientLive",
            targets: ["DeviceClientLive"]),
        .library(
            name: "DeviceFeature",
            targets: ["DeviceFeature"])
    ],
    dependencies: [
        .package(path: "KasaCore")
    ],
    targets: [
        .target(
            name: "DeviceFeature",
            dependencies: ["DeviceClient"]),
        .target(
            name: "DeviceClient",
            dependencies: ["KasaCore"]),
        .target(
            name: "DeviceClientLive",
            dependencies: [
                "DeviceClient",
                .product(name: "KasaNetworking", package: "KasaCore")
            ]),
        .testTarget(
            name: "DeviceFeatureTests",
            dependencies: ["DeviceFeature"]),
    ]
)
