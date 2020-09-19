// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UserFeature",
    defaultLocalization: "en",
    platforms: [.iOS(.v13), .watchOS(.v6)],
    products: [
        .library(
            name: "UserFeature",
            targets: ["UserFeature"]),
        .library(
            name: "UserClient",
            targets: ["UserClient"]),
        .library(
            name: "UserClientLive",
            targets: ["UserClientLive"]),
    ],
    dependencies: [
        .package(path: "KasaCore")
    ],
    targets: [
        .target(
            name: "UserFeature",
            dependencies: ["UserClient"]),
        .target(
            name: "UserClient",
            dependencies: ["KasaCore"]),
        .target(
            name: "UserClientLive",
            dependencies: [
                "UserClient",
                .product(name: "KasaNetworking", package: "KasaCore")
            ]),
        .testTarget(
            name: "UserFeatureTests",
            dependencies: ["UserFeature"]),
    ]
)
