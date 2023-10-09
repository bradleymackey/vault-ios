// swift-tools-version: 5.9

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("BareSlashRegexLiterals"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "OTPSettings",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
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
            dependencies: [],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "OTPSettingsTests",
            dependencies: ["OTPSettings", "TestHelpers"],
            swiftSettings: swiftSettings
        ),
    ]
)
