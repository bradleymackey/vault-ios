// swift-tools-version: 5.9

import PackageDescription

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
            dependencies: ["CryptoEngine"]
        ),
        .testTarget(
            name: "VaultCoreTests",
            dependencies: ["VaultCore"]
        ),
    ]
)
