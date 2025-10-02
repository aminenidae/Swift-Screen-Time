// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SubscriptionService",
    platforms: [
        .iOS(.v15),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "SubscriptionService",
            targets: ["SubscriptionService"]
        )
    ],
    dependencies: [
        .package(path: "../SharedModels"),
        .package(path: "../CloudKitService"),
        .package(path: "../RewardCore")
    ],
    targets: [
        .target(
            name: "SubscriptionService",
            dependencies: ["SharedModels", "CloudKitService", "RewardCore"]
        ),
        .testTarget(
            name: "SubscriptionServiceTests",
            dependencies: ["SubscriptionService"]
        )
    ]
)