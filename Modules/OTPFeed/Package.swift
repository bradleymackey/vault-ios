// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OTPFeed",
    defaultLocalization: "en",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(
            name: "OTPFeed",
            targets: ["OTPFeed"]
        ),
    ],
    dependencies: [
        .package(name: "OTPCore", path: "../OTPCore"),
        .package(url: "https://github.com/industrialbinaries/CombineTestExtensions", branch: "master"),
    ],
    targets: [
        .target(
            name: "OTPFeed",
            dependencies: ["OTPCore"]
        ),
        .testTarget(
            name: "OTPFeedTests",
            dependencies: ["OTPFeed", .product(name: "CombineTestExtensions", package: "CombineTestExtensions")]
        ),
    ]
)
