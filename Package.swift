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
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.8.0")),
    ],
    targets: [
        .target(name: "Midjourney", dependencies: ["Alamofire"]),
    ]
)
