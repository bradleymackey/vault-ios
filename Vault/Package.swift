// swift-tools-version: 6.0

import PackageDescription

let swiftLintVersion: Version = "0.57.0"
let swiftLintChecksum: String = "a1bbafe57538077f3abe4cfb004b0464dcd87e8c23611a2153c675574b858b3a"
let swiftFormatVersion: Version = "0.54.5"
let swiftFormatChecksum: String = "39b4530054003cf9c668b0f9391b977fc13215925aaaaa3038d6379099b8486d"

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableExperimentalFeature("AccessLevelOnImport"),
]

let targetPlugins: [Target.PluginUsage] = [
    .plugin(name: "RunMockolo"),
    .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins"),
]

let testTargetPlugins: [Target.PluginUsage] = [
    .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins"),
]

let package = Package(
    name: "Vault",
    defaultLocalization: "en",
    platforms: [.iOS("17.4"), .macOS("14.4")],
    products: [
        .library(
            name: "VaultiOS",
            targets: ["VaultiOS"]
        ),
        .executable(
            name: "keygen-speedtest",
            targets: ["VaultKeygenSpeedtest"]
        ),
        .plugin(name: "FormatLint", targets: ["FormatLint"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.17.4"),
        .package(url: "https://github.com/attaswift/BigInt.git", exact: "5.4.1"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", exact: "1.8.3"),
        .package(url: "https://github.com/sanzaru/SimpleToast.git", exact: "0.8.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.5.0"),
        .package(url: "https://github.com/twostraws/CodeScanner", exact: "2.5.0"),
        .package(url: "https://github.com/dm-zharov/swift-security.git", exact: "2.2.1"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", exact: "2.4.0"),
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", exact: swiftLintVersion),
    ],
    targets: [
        .target(
            name: "VaultiOS",
            dependencies: [
                "VaultFeed",
                "VaultSettings",
                "SimpleToast",
                "CodeScanner",
                "FoundationExtensions",
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ],
            resources: [
                .process("Resources/Feed.xcstrings"),
            ],
            swiftSettings: swiftSettings,
            plugins: targetPlugins
        ),
        .testTarget(
            name: "VaultiOSTests",
            dependencies: [
                "VaultiOS",
                "TestHelpers",
            ],
            exclude: ["__Snapshots__"],
            swiftSettings: swiftSettings,
            plugins: testTargetPlugins
        ),
        .target(
            name: "VaultBackup",
            dependencies: ["VaultCore", "VaultKeygen", "CryptoDocumentExporter", "FoundationExtensions"],
            swiftSettings: swiftSettings,
            plugins: targetPlugins
        ),
        .testTarget(
            name: "VaultBackupTests",
            dependencies: ["VaultBackup", "TestHelpers", "CryptoEngine"],
            exclude: ["__Snapshots__"],
            swiftSettings: swiftSettings,
            plugins: testTargetPlugins
        ),
        .target(
            name: "TestHelpers",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            swiftSettings: swiftSettings,
            plugins: targetPlugins
        ),
        .target(
            name: "VaultCore",
            dependencies: ["CryptoEngine", "FoundationExtensions"],
            swiftSettings: swiftSettings,
            plugins: targetPlugins
        ),
        .testTarget(
            name: "VaultCoreTests",
            dependencies: ["VaultCore", "TestHelpers"],
            swiftSettings: swiftSettings,
            plugins: testTargetPlugins
        ),
        .target(
            name: "CryptoDocumentExporter",
            dependencies: [
                "CryptoEngine",
                "FoundationExtensions",
                "ImageTools",
            ],
            swiftSettings: swiftSettings,
            plugins: targetPlugins
        ),
        .testTarget(
            name: "CryptoDocumentExporterTests",
            dependencies: [
                "CryptoDocumentExporter",
                "ImageTools",
                "TestHelpers",
            ],
            swiftSettings: swiftSettings,
            plugins: testTargetPlugins
        ),
        .testTarget(
            name: "CryptoDocumentExporterSnapshotTests",
            dependencies: [
                "CryptoDocumentExporter",
                "ImageTools",
                "TestHelpers",
                .product(
                    name: "SnapshotTesting",
                    package: "swift-snapshot-testing"
                ),
            ],
            exclude: ["__Snapshots__"],
            swiftSettings: swiftSettings,
            plugins: testTargetPlugins
        ),
        .target(
            name: "ImageTools",
            dependencies: [
                "FoundationExtensions",
            ],
            swiftSettings: swiftSettings,
            plugins: targetPlugins
        ),
        .testTarget(
            name: "ImageToolsTests",
            dependencies: [
                "ImageTools",
                "TestHelpers",
                .product(
                    name: "SnapshotTesting",
                    package: "swift-snapshot-testing"
                ),
            ],
            exclude: ["__Snapshots__"],
            swiftSettings: swiftSettings,
            plugins: testTargetPlugins
        ),
        .target(
            name: "CryptoEngine",
            dependencies: ["FoundationExtensions", "CryptoSwift", "BigInt"],
            swiftSettings: swiftSettings,
            plugins: targetPlugins
        ),
        .testTarget(
            name: "CryptoEngineTests",
            dependencies: ["CryptoEngine", "TestHelpers"],
            swiftSettings: swiftSettings,
            plugins: testTargetPlugins
        ),
        .target(
            name: "VaultSettings",
            dependencies: [
                "FoundationExtensions",
                "VaultCore",
            ],
            resources: [
                .process("Resources/Settings.xcstrings"),
            ],
            swiftSettings: swiftSettings,
            plugins: targetPlugins
        ),
        .testTarget(
            name: "VaultSettingsTests",
            dependencies: ["VaultSettings", "TestHelpers"],
            swiftSettings: swiftSettings,
            plugins: testTargetPlugins
        ),
        .target(
            name: "VaultFeed",
            dependencies: [
                "VaultBackup",
                "VaultCore",
                "CryptoEngine",
                "FoundationExtensions",
                .product(name: "SwiftSecurity", package: "swift-security"),
            ],
            resources: [
                .process("Resources/VaultFeed.xcstrings"),
            ],
            swiftSettings: swiftSettings,
            plugins: targetPlugins
        ),
        .testTarget(
            name: "VaultFeedTests",
            dependencies: ["VaultFeed", "FoundationExtensions", "TestHelpers"],
            swiftSettings: swiftSettings,
            plugins: testTargetPlugins
        ),
        .target(
            name: "FoundationExtensions",
            swiftSettings: swiftSettings,
            plugins: targetPlugins
        ),
        .testTarget(
            name: "FoundationExtensionsTests",
            dependencies: ["FoundationExtensions", "TestHelpers"],
            swiftSettings: swiftSettings,
            plugins: testTargetPlugins
        ),
        .target(
            name: "VaultKeygen",
            dependencies: ["CryptoEngine", "FoundationExtensions"],
            swiftSettings: swiftSettings,
            plugins: targetPlugins
        ),
        .testTarget(
            name: "VaultKeygenTests",
            dependencies: ["VaultKeygen", "TestHelpers"],
            swiftSettings: swiftSettings,
            plugins: testTargetPlugins
        ),
        .executableTarget(
            name: "VaultKeygenSpeedtest",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "CryptoEngine",
                "VaultKeygen",
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaultKeygenSpeedtestCompileTests",
            dependencies: ["VaultKeygenSpeedtest"],
            swiftSettings: swiftSettings
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
            name: "FormatLint",
            capability: .command(
                intent: .custom(
                    verb: "format",
                    description: "Formats Swift source files using swiftformat and swiftlint"
                ),
                permissions: [.writeToPackageDirectory(reason: "Format source code")]
            )
        ),
        .binaryTarget(
            name: "swiftformat",
            url: "https://github.com/nicklockwood/SwiftFormat/releases/download/\(swiftFormatVersion)/swiftformat.artifactbundle.zip",
            checksum: swiftFormatChecksum
        ),
        .binaryTarget(
            name: "swiftlint",
            url: "https://github.com/realm/SwiftLint/releases/download/\(swiftLintVersion)/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: swiftLintChecksum
        ),
    ]
)
