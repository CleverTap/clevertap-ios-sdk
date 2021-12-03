// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CleverTapSDK",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(
            name: "CleverTapSDK",
            targets: ["CleverTapSDK"])
    ],
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.1.0")
    ],
    targets: [
        .target(
            name: "CleverTapSDK",
            dependencies: ["SDWebImage"],
            path: "CleverTapSDK",
            exclude: [
                "Info.plist",
                "tvOS-Info.plist"
            ],
            resources: [
                .copy("DigiCertGlobalRootCA.crt"),
                .copy("DigiCertSHA2SecureServerCA.crt"),
                .process("InApps/resources"),
                .process("Inbox/resources")
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("./"),
                .headerSearchPath("DisplayUnit/"),
                .headerSearchPath("DisplayUnit/models"),
                .headerSearchPath("DisplayUnit/controllers"),
                .headerSearchPath("FeatureFlags/"),
                .headerSearchPath("FeatureFlags/models"),
                .headerSearchPath("FeatureFlags/controllers"),
                .headerSearchPath("ProductConfig/"),
                .headerSearchPath("ProductConfig/models"),
                .headerSearchPath("ProductConfig/controllers"),
                .headerSearchPath("InApps/"),
                .headerSearchPath("Inbox/"),
                .headerSearchPath("Inbox/cells"),
                .headerSearchPath("Inbox/config"),
                .headerSearchPath("Inbox/controllers"),
                .headerSearchPath("Inbox/models"),
                .headerSearchPath("Inbox/views")
            ],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("AVKit"),
                .linkedFramework("CoreData"),
                .linkedFramework("CoreServices"),
                .linkedFramework("CoreTelephony", .when(platforms: [.iOS])),
                .linkedFramework("ImageIO"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("Security"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("UserNotifications"),
                .linkedFramework("WebKit")
            ]
        )
    ]
)
