// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "OTPModels",
    platforms: [.iOS(.v13), .macOS(.v11)],
    products: [
        .library(
            name: "OTPModels",
            targets: ["OTPModels"]
        ),
    ],
    dependencies: [
        /* OTPModels should not have any dependencies */
    ],
    targets: [
        .target(
            name: "OTPModels",
            dependencies: []
        ),
        .testTarget(
            name: "OTPModelsTests",
            dependencies: ["OTPModels"]
        ),
    ]
)
