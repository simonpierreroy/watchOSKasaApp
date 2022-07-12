// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppPackage",
    platforms: [.iOS(.v15), .watchOS(.v8)],
    products: [
        .library(
            name: "AppPackage",
            targets: ["AppPackage"]),
    ],
    dependencies: [
        .package(path: "DeviceFeature"),
        .package(path: "UserFeature"),
        .package(path: "WidgetFeature")
    ],
    targets: [
        .target(
            name: "AppPackage",
            dependencies: [
                "DeviceFeature",
                "UserFeature",
                .product(name:"WidgetFeature", package: "WidgetFeature", condition: .when(platforms: [.iOS])),
                .product(name: "WidgetClientLive", package: "WidgetFeature", condition: .when(platforms: [.iOS])),
                .product(name: "UserClientLive", package: "UserFeature"),
                .product(name: "DeviceClientLive", package: "DeviceFeature")
            ]),
        .testTarget(
            name: "AppPackageTests",
            dependencies: ["AppPackage"]),
    ]
)
