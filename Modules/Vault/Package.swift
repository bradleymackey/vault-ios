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
    name: "Vault",
    products: [
        .library(
            name: "Vault",
            targets: ["Vault"]
        ),
    ],
    targets: [
        .target(
            name: "Vault",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaultTests",
            dependencies: ["Vault"],
            swiftSettings: swiftSettings
        ),
    ]
)
