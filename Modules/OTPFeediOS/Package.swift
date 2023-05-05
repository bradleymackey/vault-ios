// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OTPFeediOS",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "OTPFeediOS",
            targets: ["OTPFeediOS"]
        ),
    ],
    dependencies: [
        .package(name: "OTPFeed", path: "../OTPFeed"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.11.0"),
    ],
    targets: [
        .target(
            name: "OTPFeediOS",
            dependencies: ["OTPFeed"]
        ),
        .testTarget(
            name: "OTPFeediOSTests",
            dependencies: [
                "OTPFeediOS",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ]
)
