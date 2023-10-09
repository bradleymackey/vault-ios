// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OTPCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "OTPCore",
            targets: ["OTPCore"]
        ),
    ],
    dependencies: [
        .package(name: "CryptoEngine", path: "../CryptoEngine"),
    ],
    targets: [
        .target(
            name: "OTPCore",
            dependencies: ["CryptoEngine"]
        ),
        .testTarget(
            name: "OTPCoreTests",
            dependencies: ["OTPCore"]
        ),
    ]
)
