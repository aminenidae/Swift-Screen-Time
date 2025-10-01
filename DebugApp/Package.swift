// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DebugApp",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "DebugApp",
            targets: ["DebugApp"])
    ],
    targets: [
        .target(
            name: "DebugApp",
            dependencies: []),
        .testTarget(
            name: "DebugAppTests",
            dependencies: ["DebugApp"])
    ]
)