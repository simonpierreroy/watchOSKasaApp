// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KasaCore",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(
            name: "KasaCore",
            targets: ["KasaCore"]
        ),
        .library(
            name: "KasaNetworking",
            targets: ["KasaNetworking"]
        ),
        .library(
            name: "BaseUI",
            targets: ["BaseUI"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            exact: "1.2.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-tagged.git",
            exact: "0.10.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-parsing.git",
            exact: "0.13.0"
        ),
    ],
    targets: [
        .target(
            name: "KasaCore",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "Parsing", package: "swift-parsing"),

            ]
        ),
        .target(
            name: "KasaNetworking",
            dependencies: [
                "KasaCore"
            ]
        ),
        .target(
            name: "BaseUI",
            dependencies: []
        ),
        .testTarget(
            name: "KasaCoreTests",
            dependencies: ["KasaCore"]
        ),
    ]
)
