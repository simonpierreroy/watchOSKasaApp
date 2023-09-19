// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DeviceFeature",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(
            name: "DeviceClient",
            targets: ["DeviceClient"]
        ),
        .library(
            name: "DeviceClientLive",
            targets: ["DeviceClientLive"]
        ),
        .library(
            name: "DeviceFeature",
            targets: ["DeviceFeature"]
        ),
    ],
    dependencies: [
        .package(path: "KasaCore")
    ],
    targets: [
        .target(
            name: "DeviceFeature",
            dependencies: [
                "DeviceClient",
                .product(name: "BaseUI", package: "KasaCore"),
            ]
        ),
        .target(
            name: "DeviceClient",
            dependencies: ["KasaCore"]
        ),
        .target(
            name: "DeviceClientLive",
            dependencies: [
                "DeviceClient",
                .product(name: "KasaNetworking", package: "KasaCore"),
            ]
        ),
        .testTarget(
            name: "DeviceFeatureTests",
            dependencies: ["DeviceFeature"]
        ),
    ]
)
