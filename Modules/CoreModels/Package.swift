// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "CoreModels",
    products: [
        .library(
            name: "CoreModels",
            targets: ["CoreModels"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "CoreModels",
            dependencies: []
        ),
        .testTarget(
            name: "CoreModelsTests",
            dependencies: ["CoreModels"]
        ),
    ]
)
