// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OTPFeed",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(
            name: "OTPFeed",
            targets: ["OTPFeed"]
        ),
    ],
    dependencies: [
        .package(name: "CoreModels", path: "../CoreModels"),
        .package(name: "OTPCore", path: "../OTPCore"),
        .package(name: "CryptoEngine", path: "../CryptoEngine"),
        .package(name: "TestHelpers", path: "../TestHelpers"),
    ],
    targets: [
        .target(
            name: "OTPFeed",
            dependencies: ["OTPCore", "CryptoEngine"]
        ),
        .testTarget(
            name: "OTPFeedTests",
            dependencies: ["OTPFeed", "CoreModels", "TestHelpers"]
        ),
    ]
)
