// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("BareSlashRegexLiterals"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "VaultUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "VaultUI",
            targets: ["VaultUI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.11.0"),
    ],
    targets: [
        .target(
            name: "VaultUI",
            dependencies: [],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaultUITests",
            dependencies: [
                "VaultUI",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)
