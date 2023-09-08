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
        .package(name: "CoreUI", path: "../CoreUI"),
        .package(name: "TestHelpers", path: "../TestHelpers"),
    ],
    targets: [
        .target(
            name: "SettingsiOS",
            dependencies: ["Attribution", "CoreUI"]
        ),
        .testTarget(
            name: "SettingsiOSTests",
            dependencies: ["SettingsiOS", "TestHelpers"]
        ),
    ]
)
