// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OTPAttribution",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "OTPAttribution",
            targets: ["OTPAttribution"]
        ),
    ],
    dependencies: [
        .package(name: "FoundationExtensions", path: "../FoundationExtensions"),
    ],
    targets: [
        .target(
            name: "OTPAttribution",
            dependencies: ["FoundationExtensions"],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "OTPAttributionTests",
            dependencies: ["OTPAttribution"]
        ),
    ]
)
