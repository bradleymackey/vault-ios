// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OTPCore",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
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
