// swift-tools-version: 5.9

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("BareSlashRegexLiterals"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("StrictConcurrency"),
]

let package = Package(
    name: "VaultSettings",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "VaultSettings",
            targets: ["VaultSettings"]
        ),
    ],
    dependencies: [
        .package(name: "TestHelpers", path: "../TestHelpers"),
        .package(name: "FoundationExtensions", path: "../FoundationExtensions"),
    ],
    targets: [
        .target(
            name: "VaultSettings",
            dependencies: ["FoundationExtensions"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaultSettingsTests",
            dependencies: ["VaultSettings", "TestHelpers"],
            swiftSettings: swiftSettings
        ),
    ]
)
