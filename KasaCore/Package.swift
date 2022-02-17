// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KasaCore",
    platforms: [.iOS(.v15), .watchOS(.v8)],
    products: [
        .library(
            name: "KasaCore",
            targets: ["KasaCore"]),
        .library(
            name: "KasaNetworking",
            targets: ["KasaNetworking"]),
        .library(
            name: "BaseUI",
            targets: ["BaseUI"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            .exact("0.33.1")
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-tagged.git",
            .exact("0.6.0")
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-parsing.git",
            .exact("0.7.0")
        ),
    ],
    targets: [
        .target(
            name: "KasaCore",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "Parsing", package: "swift-parsing")

            ]),
        .target(
            name: "KasaNetworking",
            dependencies: [
                "KasaCore"
            ]),
        .target(
            name: "BaseUI",
            dependencies: []),
        .testTarget(
            name: "KasaCoreTests",
            dependencies: ["KasaCore"]),
    ]
)
