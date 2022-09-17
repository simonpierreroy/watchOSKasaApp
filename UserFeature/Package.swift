// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UserFeature",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .watchOS(.v9)],
    products: [
        .library(
            name: "UserFeature",
            targets: ["UserFeature"]
        ),
        .library(
            name: "UserClient",
            targets: ["UserClient"]
        ),
        .library(
            name: "UserClientLive",
            targets: ["UserClientLive"]
        ),
    ],
    dependencies: [
        .package(path: "KasaCore")
    ],
    targets: [
        .target(
            name: "UserFeature",
            dependencies: [
                "UserClient",
                .product(name: "BaseUI", package: "KasaCore")
            ]),
        .target(
            name: "UserClient",
            dependencies: ["KasaCore"]
        ),
        .target(
            name: "UserClientLive",
            dependencies: [
                "UserClient",
                .product(name: "KasaNetworking", package: "KasaCore")
            ]),
        .testTarget(
            name: "UserFeatureTests",
            dependencies: ["UserFeature"]
        ),
    ]
)
