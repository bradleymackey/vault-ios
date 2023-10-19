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
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Vault",
            targets: ["Vault"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.11.0"),
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.9.6"),
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", from: "1.7.0"),
        .package(url: "https://github.com/sanzaru/SimpleToast.git", from: "0.8.0"),
    ],
    targets: [
        .target(
            name: "Vault",
            dependencies: ["VaultUI", "VaultFeed", "VaultFeediOS", "VaultSettings", "VaultCore"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaultTests",
            dependencies: ["Vault"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "TestHelpers",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "ViewInspector", package: "ViewInspector"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "VaultCore",
            dependencies: ["CryptoEngine"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaultCoreTests",
            dependencies: ["VaultCore", "TestHelpers"],
            swiftSettings: swiftSettings
        ),
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
        .target(
            name: "CryptoDocumentExporter",
            dependencies: ["CryptoEngine"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "CryptoDocumentExporterTests",
            dependencies: [
                "CryptoDocumentExporter",
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "CryptoDocumentExporterSnapshotTests",
            dependencies: [
                "CryptoDocumentExporter",
                .product(
                    name: "SnapshotTesting",
                    package: "swift-snapshot-testing"
                ),
            ],
            exclude: ["__Snapshots__"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "CryptoEngine",
            dependencies: ["CryptoSwift", "BigInt"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "CryptoEngineTests",
            dependencies: ["CryptoEngine"],
            swiftSettings: swiftSettings
        ),
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
        .target(
            name: "VaultFeed",
            dependencies: ["VaultCore", "CryptoEngine"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaultFeedTests",
            dependencies: ["VaultFeed", "FoundationExtensions", "TestHelpers"],
            swiftSettings: swiftSettings
        ),
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
        .target(
            name: "FoundationExtensions",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "FoundationExtensionsTests",
            dependencies: ["FoundationExtensions"],
            swiftSettings: swiftSettings
        ),
    ]
)
