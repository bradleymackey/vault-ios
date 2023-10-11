// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OTPFeed",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "OTPFeed",
            targets: ["OTPFeed"]
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
            name: "OTPFeed",
            dependencies: ["VaultCore", "CryptoEngine"]
        ),
        .testTarget(
            name: "OTPFeedTests",
            dependencies: ["OTPFeed", "FoundationExtensions", "TestHelpers"]
        ),
    ]
)
