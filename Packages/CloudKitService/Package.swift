// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CloudKitService",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "CloudKitService",
            targets: ["CloudKitService"])
    ],
    dependencies: [
        .package(path: "../SharedModels"),
        .package(path: "../FamilyControlsKit")
    ],
    targets: [
        .target(
            name: "CloudKitService",
            dependencies: ["SharedModels", "FamilyControlsKit"]),
        .testTarget(
            name: "CloudKitServiceTests",
            dependencies: ["CloudKitService"])
    ]
)