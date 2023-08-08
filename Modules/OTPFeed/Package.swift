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
        .package(name: "OTPCore", path: "../OTPCore"),
        .package(name: "CryptoEngine", path: "../CryptoEngine"),
    ],
    targets: [
        .target(
            name: "OTPFeed",
            dependencies: ["OTPCore", "CryptoEngine"]
        ),
        .testTarget(
            name: "OTPFeedTests",
            dependencies: ["OTPFeed"]
        ),
    ]
)
