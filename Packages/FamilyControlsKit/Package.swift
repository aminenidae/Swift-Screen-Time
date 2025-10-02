// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FamilyControlsKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "FamilyControlsKit",
            targets: ["FamilyControlsKit"])
    ],
    dependencies: [
        .package(path: "../SharedModels")
    ],
    targets: [
        .target(
            name: "FamilyControlsKit",
            dependencies: ["SharedModels"]),
        .testTarget(
            name: "FamilyControlsKitTests",
            dependencies: ["FamilyControlsKit"])
    ]
)