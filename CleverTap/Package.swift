// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CleverTap",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(
            name: "CleverTap",
            targets: ["CleverTap"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.1.0")
    ],
    targets: [
        .target(
            name: "CleverTap",
            dependencies: ["SDWebImage"]
        ),
        .testTarget(
            name: "CleverTapTests",
            dependencies: ["CleverTap"]
        ),
    ]
)
