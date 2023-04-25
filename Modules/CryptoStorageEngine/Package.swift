// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "CryptoStorageEngine",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(
            name: "CryptoStorageEngine",
            targets: ["CryptoStorageEngine"]
        ),
    ],
    targets: [
        .target(
            name: "CryptoStorageEngine"),
        .testTarget(
            name: "CryptoStorageEngineTests",
            dependencies: ["CryptoStorageEngine"]
        ),
    ]
)
