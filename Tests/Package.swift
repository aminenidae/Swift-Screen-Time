// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScreenTimeRewardsTests",
    platforms: [
        .iOS(.v15)
    ],
    dependencies: [
        .package(path: "../Packages/CloudKitService"),
        .package(path: "../Packages/SharedModels")
    ],
    targets: [
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "CloudKitService",
                "SharedModels"
            ],
            path: "Tests/IntegrationTests"
        ),
        .testTarget(
            name: "PerformanceTests",
            dependencies: [
                "CloudKitService",
                "SharedModels"
            ],
            path: "Tests/PerformanceTests"
        )
    ]
)