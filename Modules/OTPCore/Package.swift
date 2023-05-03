// swift-tools-version: 5.8

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
    targets: [
        .target(
            name: "OTPCore"
        ),
        .testTarget(
            name: "OTPCoreTests",
            dependencies: ["OTPCore"]
        ),
    ]
)
