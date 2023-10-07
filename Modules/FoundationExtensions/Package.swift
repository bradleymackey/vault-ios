// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FoundationExtensions",
    defaultLocalization: "en",
    platforms: [.iOS(.v13), .macOS(.v11)],
    products: [
        .library(
            name: "FoundationExtensions",
            targets: ["FoundationExtensions"]
        ),
    ],
    targets: [
        .target(
            name: "FoundationExtensions"
        ),
        .testTarget(
            name: "FoundationExtensionsTests",
            dependencies: ["FoundationExtensions"]
        ),
    ]
)
