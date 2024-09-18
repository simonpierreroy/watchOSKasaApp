// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KasaCore",
    platforms: [.iOS(.v18), .watchOS(.v11)],
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
            exact: "1.15.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-tagged.git",
            exact: "0.10.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-parsing.git",
            exact: "0.13.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-dependencies",
            from: "1.4.0"
        ),
    ],
    targets: [
        .target(
            name: "KasaCore",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "Parsing", package: "swift-parsing"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
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
    ],
    swiftLanguageModes: [.v6]
)
