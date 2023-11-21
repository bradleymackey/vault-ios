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
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "VaultiOS",
            targets: ["VaultiOS"]
        ),
        .plugin(name: "FormatSwift", targets: ["FormatSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.14.2"),
        .package(url: "https://github.com/nalexn/ViewInspector", exact: "0.9.8"),
        .package(url: "https://github.com/attaswift/BigInt.git", exact: "5.3.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", exact: "1.8.0"),
        .package(url: "https://github.com/sanzaru/SimpleToast.git", exact: "0.8.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.2.3"),
    ],
    targets: [
        .target(
            name: "VaultiOS",
            dependencies: [
                "VaultFeed",
                "VaultSettings",
                "VaultCore",
                "SimpleToast",
                "FoundationExtensions",
                .targetItem(name: "VaultUI", condition: .when(platforms: [.iOS])),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaultiOSTests",
            dependencies: [
                "VaultiOS",
                "TestHelpers",
            ],
            exclude: ["__Snapshots__"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "VaultBackup",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaultBackupTests",
            dependencies: ["VaultBackup", "TestHelpers"],
            exclude: ["__Snapshots__"],
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
            exclude: ["__Snapshots__"],
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
            resources: [
                .copy("Resources/VaultStore.xcdatamodeld"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaultFeedTests",
            dependencies: ["VaultFeed", "FoundationExtensions", "TestHelpers"],
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

        // MARK: - TOOLING

        .plugin(
            name: "FormatSwift",
            capability: .command(
                intent: .custom(
                    verb: "format",
                    description: "Formats Swift source files using swiftformat and swiftlint"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Format Swift source files"),
                ]
            ),
            dependencies: [
                "SwiftFormatTool",
                "swiftformat",
                "swiftlint",
            ]
        ),
        .executableTarget(
            name: "SwiftFormatTool",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            resources: [
                .process("default.swiftformat"),
                .process("swiftlint.yml"),
            ]
        ),

        .binaryTarget(
            name: "swiftformat",
            url: "https://github.com/nicklockwood/SwiftFormat/releases/download/0.52.8/swiftformat.artifactbundle.zip",
            checksum: "4ffc4d52d67feefa9576ceb1c83bbd1cb0832d735fa85ac580dc7453ce3face0"
        ),
        .binaryTarget(
            name: "swiftlint",
            url: "https://github.com/realm/SwiftLint/releases/download/0.53.0/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "03416a4f75f023e10f9a76945806ddfe70ca06129b895455cc773c5c7d86b73e"
        ),
    ]
)
