// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CryptoExporter",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CryptoExporter",
            targets: ["CryptoExporter"]
        ),
    ],
    dependencies: [
        .package(name: "CryptoEngine", path: "../CryptoEngine"),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            .upToNextMajor(from: "1.11.0")
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CryptoExporter",
            dependencies: ["CryptoEngine"]
        ),
        .testTarget(
            name: "CryptoExporterTests",
            dependencies: [
                "CryptoExporter",
            ]
        ),
        .testTarget(
            name: "CryptoExporterSnapshotTests",
            dependencies: [
                "CryptoExporter",
                .product(
                    name: "SnapshotTesting",
                    package: "swift-snapshot-testing"
                ),
            ],
            exclude: ["__Snapshots__"]
        ),
    ]
)
