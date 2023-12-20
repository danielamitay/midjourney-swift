// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "midjourney-swift",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "Midjourney",
            targets: ["Midjourney"]
        ),
    ],
    targets: [
        .target(name: "Midjourney"),
    ]
)
