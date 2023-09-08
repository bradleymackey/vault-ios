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
        .package(name: "OTPFeed", path: "../OTPFeed"),
        .package(name: "CoreUI", path: "../CoreUI"),
        .package(name: "CoreModels", path: "../CoreModels"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.11.0"),
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.9.6"),
        .package(url: "https://github.com/elai950/AlertToast", from: "1.3.9"),
    ],
    targets: [
        .target(
            name: "OTPFeediOS",
            dependencies: ["OTPFeed", "AlertToast", "CoreUI", "CoreModels"]
        ),
        .testTarget(
            name: "OTPFeediOSTests",
            dependencies: [
                "OTPFeediOS",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "ViewInspector", package: "ViewInspector"),
            ]
        ),
    ]
)
