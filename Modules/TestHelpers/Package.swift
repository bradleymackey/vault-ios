// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "TestHelpers",
    platforms: [.iOS(.v13), .macOS(.v11)],
    products: [
        .library(
            name: "TestHelpers",
            targets: ["TestHelpers"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.11.0"),
    ],
    targets: [
        .target(
            name: "TestHelpers",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ]
)
