// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("BareSlashRegexLiterals"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("StrictConcurrency"),
]

let package = Package(
    name: "VaultFeed",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "VaultFeed",
            targets: ["VaultFeed"]
        ),
    ],
    dependencies: [
        .package(name: "FoundationExtensions", path: "../FoundationExtensions"),
        .package(name: "VaultCore", path: "../VaultCore"),
        .package(name: "CryptoEngine", path: "../CryptoEngine"),
        .package(name: "TestHelpers", path: "../TestHelpers"),
    ],
    targets: [
        .target(
            name: "VaultFeed",
            dependencies: ["VaultCore", "CryptoEngine"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaultFeedTests",
            dependencies: ["VaultFeed", "FoundationExtensions", "TestHelpers"],
            swiftSettings: swiftSettings
        ),
    ]
)
