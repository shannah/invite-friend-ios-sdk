// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InviteKit",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        // Main SDK for the full application
        .library(
            name: "InviteKit",
            targets: ["InviteKit"]
        ),
        // Lightweight SDK for App Clips
        .library(
            name: "CN1InviteKit",
            targets: ["CN1InviteKit"]
        )
    ],
    dependencies: [],
    targets: [
        // MARK: - Main SDK
        .target(
            name: "InviteKit",
            dependencies: [],
            path: "Sources/InviteKit"
        ),

        // MARK: - App Clip SDK
        .target(
            name: "CN1InviteKit",
            dependencies: [],
            path: "Sources/CN1InviteKit"
        ),

        // MARK: - Tests
        .testTarget(
            name: "InviteKitTests",
            dependencies: ["InviteKit"],
            path: "Tests/InviteKitTests"
        ),
        .testTarget(
            name: "CN1InviteKitTests",
            dependencies: ["CN1InviteKit"],
            path: "Tests/CN1InviteKitTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
