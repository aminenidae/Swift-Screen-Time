// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SharedModels",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SharedModels",
            targets: ["SharedModels"])
    ],
    targets: [
        .target(
            name: "SharedModels",
            dependencies: []),
        .testTarget(
            name: "SharedModelsTests",
            dependencies: ["SharedModels"])
    ]
)