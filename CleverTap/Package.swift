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
            cSettings: [
                .headerSearchPath("CleverTapSDK"),
                .headerSearchPath("ABTesting"),
                .headerSearchPath("ABTesting/controllers"),
                .headerSearchPath("ABTesting/models"), // TODO: added all ABTesting subfolders!
                .headerSearchPath("DisplayUnit"),
                .headerSearchPath("DisplayUnit/controllers"),
                .headerSearchPath("DisplayUnit/models"),
                .headerSearchPath("FeatureFlags"),
                .headerSearchPath("FeatureFlags/controllers"),
                .headerSearchPath("FeatureFlags/models"),
                .headerSearchPath("InApps"),
                .headerSearchPath("InApps/images"),
                .headerSearchPath("Inbox"),
                .headerSearchPath("Inbox/cells"),
                .headerSearchPath("Inbox/config"),
                .headerSearchPath("Inbox/controllers"),
                .headerSearchPath("Inbox/images"),
                .headerSearchPath("Inbox/models"),
                .headerSearchPath("Inbox/views"),
                .headerSearchPath("ProductConfig"),
                .headerSearchPath("ProductConfig/models"),
                .headerSearchPath("ProductConfig/controllers")
            ],
        ),
        .testTarget(
            name: "CleverTapTests",
            dependencies: ["CleverTap"]
        ),
    ]
)
