// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ZvukMusic",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "ZvukMusic",
            targets: ["ZvukMusic"]
        ),
    ],
    targets: [
        .target(
            name: "ZvukMusic",
            resources: [
                .copy("Resources/Queries"),
                .copy("Resources/Mutations"),
            ]
        ),
        .testTarget(
            name: "ZvukMusicTests",
            dependencies: ["ZvukMusic"]
        ),
    ]
)
