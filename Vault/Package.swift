// swift-tools-version: 5.10

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("BareSlashRegexLiterals"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("StrictConcurrency"),
    .define("SPYABLE", .when(configuration: .debug)),
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
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.16.0"),
        .package(url: "https://github.com/nalexn/ViewInspector", exact: "0.9.10"),
        .package(url: "https://github.com/attaswift/BigInt.git", exact: "5.3.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", exact: "1.8.2"),
        .package(url: "https://github.com/sanzaru/SimpleToast.git", exact: "0.8.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.3.1"),
        .package(url: "https://github.com/bradleymackey/swift-spyable", branch: "main"),
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
            resources: [
                .process("Resources/Feed.xcstrings"),
            ],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .testTarget(
            name: "VaultiOSTests",
            dependencies: [
                "VaultiOS",
                "TestHelpers",
            ],
            exclude: ["__Snapshots__"],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .target(
            name: "VaultBackup",
            dependencies: ["CryptoDocumentExporter"],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .testTarget(
            name: "VaultBackupTests",
            dependencies: ["VaultBackup", "TestHelpers", "CryptoEngine"],
            exclude: ["__Snapshots__"],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .target(
            name: "TestHelpers",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "ViewInspector", package: "ViewInspector"),
            ],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .target(
            name: "VaultCore",
            dependencies: ["CryptoEngine"],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .testTarget(
            name: "VaultCoreTests",
            dependencies: ["VaultCore", "TestHelpers"],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .target(
            name: "VaultUI",
            dependencies: [],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .testTarget(
            name: "VaultUITests",
            dependencies: [
                "VaultUI",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            exclude: ["__Snapshots__"],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .target(
            name: "CryptoDocumentExporter",
            dependencies: [
                "CryptoEngine",
                .product(name: "Spyable", package: "swift-spyable"),
            ],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .testTarget(
            name: "CryptoDocumentExporterTests",
            dependencies: [
                "CryptoDocumentExporter",
                "TestHelpers",
            ],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .testTarget(
            name: "CryptoDocumentExporterSnapshotTests",
            dependencies: [
                "CryptoDocumentExporter",
                "TestHelpers",
                .product(
                    name: "SnapshotTesting",
                    package: "swift-snapshot-testing"
                ),
            ],
            exclude: ["__Snapshots__"],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .target(
            name: "CryptoEngine",
            dependencies: ["CryptoSwift", "BigInt"],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .testTarget(
            name: "CryptoEngineTests",
            dependencies: ["CryptoEngine"],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .target(
            name: "VaultSettings",
            dependencies: ["FoundationExtensions"],
            resources: [
                .process("Resources/Settings.xcstrings"),
            ],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .testTarget(
            name: "VaultSettingsTests",
            dependencies: ["VaultSettings", "TestHelpers"],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .target(
            name: "VaultFeed",
            dependencies: [
                "VaultCore",
                "CryptoEngine",
                .product(name: "Spyable", package: "swift-spyable"),
            ],
            resources: [
                .copy("Resources/VaultStore.xcdatamodeld"),
                .process("Resources/VaultFeed.xcstrings"),
            ],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .testTarget(
            name: "VaultFeedTests",
            dependencies: ["VaultFeed", "FoundationExtensions", "TestHelpers"],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .target(
            name: "FoundationExtensions",
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .testTarget(
            name: "FoundationExtensionsTests",
            dependencies: ["FoundationExtensions", "TestHelpers"],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),

        // MARK: - TOOLING

        .plugin(
            name: "RunMockolo",
            capability: .buildTool(),
            dependencies: [.target(name: "mockolo")]
        ),
        .binaryTarget(
            name: "mockolo",
            url: "https://github.com/uber/mockolo/releases/download/2.1.1/mockolo.artifactbundle.zip",
            checksum: "e3aa6e3aacec6b75ee971d7ba1ed326ff22372a8dc60a581cec742441cdbd9db"
        ),

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
            url: "https://github.com/nicklockwood/SwiftFormat/releases/download/0.53.6/swiftformat.artifactbundle.zip",
            checksum: "588b4469708decd9944717fbd284095189f63c720de3bae781e6487004b18d90"
        ),
        .binaryTarget(
            name: "swiftlint",
            url: "https://github.com/realm/SwiftLint/releases/download/0.54.0/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "963121d6babf2bf5fd66a21ac9297e86d855cbc9d28322790646b88dceca00f1"
        ),
    ]
)
