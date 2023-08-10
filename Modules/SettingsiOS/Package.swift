// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "SettingsiOS",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "SettingsiOS",
            targets: ["SettingsiOS"]
        ),
    ],
    dependencies: [
        .package(name: "Attribution", path: "../Attribution"),
    ],
    targets: [
        .target(
            name: "SettingsiOS",
            dependencies: ["Attribution"]
        ),
        .testTarget(
            name: "SettingsiOSTests",
            dependencies: ["SettingsiOS"]
        ),
    ]
)
