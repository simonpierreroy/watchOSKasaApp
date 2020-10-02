// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppPackage",
    platforms: [.iOS(.v14), .watchOS(.v7)],
    products: [
        .library(
            name: "AppPackage",
            targets: ["AppPackage"]),
    ],
    dependencies: [
        .package(path: "DeviceFeature"),
        .package(path: "UserFeature")
    ],
    targets: [
        .target(
            name: "AppPackage",
            dependencies: [
                "DeviceFeature",
                "UserFeature",
                .product(name: "UserClientLive", package: "UserFeature"),
                .product(name: "DeviceClientLive", package: "DeviceFeature")
            ]),
        .testTarget(
            name: "AppPackageTests",
            dependencies: ["AppPackage"]),
    ]
)
