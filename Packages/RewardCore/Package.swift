// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RewardCore",
    platforms: [
        .iOS(.v15),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "RewardCore",
            targets: ["RewardCore"]
        )
    ],
    dependencies: [
        .package(path: "../SharedModels"),
        .package(path: "../CloudKitService"),
        .package(path: "../FamilyControlsKit")
    ],
    targets: [
        .target(
            name: "RewardCore",
            dependencies: [
                "SharedModels",
                "CloudKitService",
                "FamilyControlsKit"
            ]
        ),
        .testTarget(
            name: "RewardCoreTests",
            dependencies: ["RewardCore"]
        )
    ]
)