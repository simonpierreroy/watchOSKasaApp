// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KasaCore",
    platforms: [.iOS(.v13), .watchOS(.v6)],
    products: [
        .library(
            name: "KasaCore",
            targets: ["KasaCore"]),
        .library(
            name: "KasaNetworking",
            targets: ["KasaNetworking"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            from: "0.8.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-tagged.git",
            .revision("6c36cf66f58553d0481a2628e3e27177f698a897")
        ),
    ],
    targets: [
        .target(
            name: "KasaCore",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Tagged", package: "swift-tagged")
            ]),
        .target(
            name: "KasaNetworking",
            dependencies: [
                "KasaCore"
            ]),
        .testTarget(
            name: "KasaCoreTests",
            dependencies: ["KasaCore"]),
    ]
)