// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency"),
]

let package = Package(
    name: "VaultFeediOS",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "VaultFeediOS",
            targets: ["VaultFeediOS"]
        ),
    ],
    dependencies: [
        .package(name: "VaultFeed", path: "../VaultFeed"),
        .package(name: "VaultUI", path: "../VaultUI"),
        .package(name: "FoundationExtensions", path: "../FoundationExtensions"),
        .package(name: "VaultSettings", path: "../VaultSettings"),
        .package(name: "TestHelpers", path: "../TestHelpers"),
        .package(url: "https://github.com/sanzaru/SimpleToast.git", from: "0.8.0"),
    ],
    targets: [
        .target(
            name: "VaultFeediOS",
            dependencies: ["VaultFeed", "SimpleToast", "VaultUI", "FoundationExtensions", "VaultSettings"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaultFeediOSTests",
            dependencies: [
                "VaultFeediOS",
                "TestHelpers",
            ],
            swiftSettings: swiftSettings
        ),
    ]
)
