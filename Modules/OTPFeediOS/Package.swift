// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OTPFeediOS",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "OTPFeediOS",
            targets: ["OTPFeediOS"]
        ),
    ],
    dependencies: [
        .package(name: "Attribution", path: "../Attribution"),
        .package(name: "OTPFeed", path: "../OTPFeed"),
        .package(name: "OTPUI", path: "../OTPUI"),
        .package(name: "OTPModels", path: "../OTPModels"),
        .package(name: "TestHelpers", path: "../TestHelpers"),
        .package(url: "https://github.com/elai950/AlertToast", from: "1.3.9"),
    ],
    targets: [
        .target(
            name: "OTPFeediOS",
            dependencies: ["OTPFeed", "AlertToast", "OTPUI", "OTPModels", "Attribution"]
        ),
        .testTarget(
            name: "OTPFeediOSTests",
            dependencies: [
                "OTPFeediOS",
                "TestHelpers",
            ]
        ),
    ]
)
