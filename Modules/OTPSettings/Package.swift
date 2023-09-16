// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "OTPSettings",
    products: [
        .library(
            name: "OTPSettings",
            targets: ["OTPSettings"]
        ),
    ],
    dependencies: [
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "OTPSettings",
            dependencies: []
        ),
        .testTarget(
            name: "OTPSettingsTests",
            dependencies: ["OTPSettings"]
        ),
    ]
)
