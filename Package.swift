// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CleverTapSDK",
    defaultLocalization: "en",
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
                .process("InApps/images"),
                .process("InApps/xibs"),
                .process("Inbox/images"),
                .process("ios.modulemap"),
                .process("tvos.modulemap"),
                .copy("DigiCertGlobalRootCA.crt"),
                .copy("DigiCertSHA2SecureServerCA.crt")
            ],
            cSettings: [
                .headerSearchPath("./"),
                .headerSearchPath("ABTesting/"),
                .headerSearchPath("ABTesting/controllers/"),
                .headerSearchPath("ABTesting/models"),
                .headerSearchPath("ABTesting/uieditor/"),
                .headerSearchPath("ABTesting/uieditor/messages"),
                .headerSearchPath("ABTesting/uieditor/websocket"),
                .headerSearchPath("ABTesting/uieditor/serializers"),
                .headerSearchPath("ABTesting/uieditor/transformers"),
                .headerSearchPath("ABTesting/utils"),
                .headerSearchPath("DisplayUnit/"),
                .headerSearchPath("DisplayUnit/controllers"),
                .headerSearchPath("DisplayUnit/models"),
                .headerSearchPath("FeatureFlags/"),
                .headerSearchPath("FeatureFlags/controllers"),
                .headerSearchPath("FeatureFlags/models"),
                .headerSearchPath("InApps/"),
                .headerSearchPath("Inbox/"),
                .headerSearchPath("Inbox/cells"),
                .headerSearchPath("Inbox/config"),
                .headerSearchPath("Inbox/controllers"),
                .headerSearchPath("Inbox/images"),
                .headerSearchPath("Inbox/models"),
                .headerSearchPath("Inbox/views"),
                .headerSearchPath("ProductConfig/"),
                .headerSearchPath("ProductConfig/models"),
                .headerSearchPath("ProductConfig/controllers")
            ],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("AVKit"),
                .linkedFramework("CoreData"),
                .linkedFramework("CoreLocation"),
                .linkedFramework("CoreServices"),
                .linkedFramework("CoreTelephony"),
                .linkedFramework("ImageIO"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("Security"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("UIKit"),
                .linkedFramework("UserNotifications"),
                .linkedFramework("WebKit")
            ]
        )
    ]
)
