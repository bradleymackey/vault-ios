// swift-tools-version: 5.8

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
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "OTPAttribution",
            dependencies: [],
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
