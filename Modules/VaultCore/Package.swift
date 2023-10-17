// swift-tools-version: 5.9

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency"),
]

let package = Package(
    name: "VaultCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "VaultCore",
            targets: ["VaultCore"]
        ),
    ],
    dependencies: [
        .package(name: "CryptoEngine", path: "../CryptoEngine"),
    ],
    targets: [
        .target(
            name: "VaultCore",
            dependencies: ["CryptoEngine"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaultCoreTests",
            dependencies: ["VaultCore"],
            swiftSettings: swiftSettings
        ),
    ]
)
