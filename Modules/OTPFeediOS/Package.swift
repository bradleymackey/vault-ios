// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OTPFeediOS",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "OTPFeediOS",
            targets: ["OTPFeediOS"]
        ),
    ],
    dependencies: [
        .package(name: "OTPAttribution", path: "../OTPAttribution"),
        .package(name: "OTPFeed", path: "../OTPFeed"),
        .package(name: "OTPUI", path: "../OTPUI"),
        .package(name: "FoundationExtensions", path: "../FoundationExtensions"),
        .package(name: "OTPSettings", path: "../OTPSettings"),
        .package(name: "TestHelpers", path: "../TestHelpers"),
        .package(url: "https://github.com/sanzaru/SimpleToast.git", from: "0.8.0"),
    ],
    targets: [
        .target(
            name: "OTPFeediOS",
            dependencies: ["OTPFeed", "SimpleToast", "OTPUI", "FoundationExtensions", "OTPSettings", "OTPAttribution"]
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
