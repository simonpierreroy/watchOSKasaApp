// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WidgetFeature",
    defaultLocalization: "en",
    platforms: [.iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "WidgetFeature",
            targets: ["WidgetFeature"]),
        .library(
            name: "WidgetClient",
            targets: ["WidgetClient"]),
        .library(
            name: "WidgetClientLive",
            targets: ["WidgetClientLive"])
    ],
    dependencies: [
        .package(path: "KasaCore"),
        .package(path: "DeviceFeature"),
        .package(path: "UserFeature")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "WidgetFeature",
            dependencies: ["KasaCore", "WidgetClient"]),
        .target(
            name: "WidgetClient",
            dependencies: [
                .product(name: "DeviceClient", package: "DeviceFeature"),
                .product(name: "UserClient", package: "UserFeature"),
            ]),
        .target(
            name: "WidgetClientLive",
            dependencies: [
                "WidgetClient",
                .product(name: "DeviceClientLive", package: "DeviceFeature"),
                .product(name: "UserClientLive", package: "UserFeature"),
            ]),
        .testTarget(
            name: "WidgetFeatureTests",
            dependencies: ["WidgetFeature"]),
    ]
)
