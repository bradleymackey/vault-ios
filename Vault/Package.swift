// swift-tools-version: 5.10

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("BareSlashRegexLiterals"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("GlobalConcurrency"),
    .enableUpcomingFeature("IsolatedDefaultValues"),
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableUpcomingFeature("ImportObjcForwardDeclarations"),
    .enableUpcomingFeature("DeprecateApplicationMain"),
    .enableUpcomingFeature("ImplicitOpenExistentials"),
    .enableUpcomingFeature("StrictConcurrency"), // For Swift 6
    .enableExperimentalFeature("StrictConcurrency"), // For Swift 5.10
    .enableExperimentalFeature("AccessLevelOnImport"),
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
        .plugin(name: "FormatSwift", targets: ["FormatSwift"]),
        .executable(
            name: "KeygenSpeedtest",
            targets: ["KeygenSpeedtest"]
        ),
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
    ],
    targets: [
        .target(
            name: "VaultiOS",
            dependencies: [
                "VaultFeed",
                "VaultSettings",
                "VaultCore",
                "SimpleToast",
                "CodeScanner",
                "FoundationExtensions",
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
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
            swiftSettings: swiftSettings
        ),
        .target(
            name: "VaultBackup",
            dependencies: ["VaultCore", "CryptoDocumentExporter", "FoundationExtensions"],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .testTarget(
            name: "VaultBackupTests",
            dependencies: ["VaultBackup", "TestHelpers", "CryptoEngine"],
            exclude: ["__Snapshots__"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "TestHelpers",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "VaultCore",
            dependencies: ["CryptoEngine", "FoundationExtensions"],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .testTarget(
            name: "VaultCoreTests",
            dependencies: ["VaultCore", "TestHelpers"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "CryptoDocumentExporter",
            dependencies: [
                "CryptoEngine",
                "FoundationExtensions",
                "ImageTools",
            ],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .testTarget(
            name: "CryptoDocumentExporterTests",
            dependencies: [
                "CryptoDocumentExporter",
                "ImageTools",
                "TestHelpers",
            ],
            swiftSettings: swiftSettings
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
            swiftSettings: swiftSettings
        ),
        .target(
            name: "ImageTools",
            dependencies: [
                "FoundationExtensions",
            ],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
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
            swiftSettings: swiftSettings
        ),
        .target(
            name: "CryptoEngine",
            dependencies: ["FoundationExtensions", "CryptoSwift", "BigInt"],
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .testTarget(
            name: "CryptoEngineTests",
            dependencies: ["CryptoEngine", "TestHelpers"],
            swiftSettings: swiftSettings
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
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .testTarget(
            name: "VaultSettingsTests",
            dependencies: ["VaultSettings", "TestHelpers"],
            swiftSettings: swiftSettings
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
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .testTarget(
            name: "VaultFeedTests",
            dependencies: ["VaultFeed", "FoundationExtensions", "TestHelpers"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "FoundationExtensions",
            swiftSettings: swiftSettings,
            plugins: [.plugin(name: "RunMockolo")]
        ),
        .testTarget(
            name: "FoundationExtensionsTests",
            dependencies: ["FoundationExtensions", "TestHelpers"],
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
            url: "https://github.com/nicklockwood/SwiftFormat/releases/download/0.54.3/swiftformat.artifactbundle.zip",
            checksum: "b9d4e1a76449ab0c3beb3eb34fb3dcf396589afb1ee75764767a6ef541c63d67"
        ),
        .binaryTarget(
            name: "swiftlint",
            url: "https://github.com/realm/SwiftLint/releases/download/0.56.1/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "146ef723e83d301b9f1ef647dc924a55dae293887e633618e76f8cb526292f0c"
        ),
        .executableTarget(
            name: "KeygenSpeedtest",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "CryptoEngine",
            ],
            swiftSettings: swiftSettings
        ),
    ]
)
