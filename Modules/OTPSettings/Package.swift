// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OTPSettings",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "OTPSettings",
            targets: ["OTPSettings"]
        ),
    ],
    dependencies: [
        .package(name: "TestHelpers", path: "../TestHelpers"),
    ],
    targets: [
        .target(
            name: "OTPSettings",
            dependencies: []
        ),
        .testTarget(
            name: "OTPSettingsTests",
            dependencies: ["OTPSettings", "TestHelpers"]
        ),
    ]
)
