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
            targets: ["CleverTap"])
    ],
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.1.0")
    ],
    targets: [
        .target(
            name: "CleverTap",
            dependencies: ["SDWebImage"],
            path: "CleverTapSDK",
            exclude: [
                "Info.plist",
                "tvOS-Info.plist"
            ],
            resources: [
                .process("InApps/images/ic_expand@1x.png"),
                .process("InApps/images/ic_expand@2x.png"),
                .process("InApps/images/ic_expand@3x.png"),
                .process("InApps/images/ic_pause@1x.png"),
                .process("InApps/images/ic_pause@2x.png"),
                .process("InApps/images/ic_pause@3x.png"),
                .process("InApps/images/ic_play@1x.png"),
                .process("InApps/images/ic_play@2x.png"),
                .process("InApps/images/ic_play@3x.png"),
                .process("InApps/images/ic_shrink@1x.png"),
                .process("InApps/images/ic_shrink@2x.png"),
                .process("InApps/images/ic_shrink@3x.png"),
                .process("InApps/images/ic_thumb.png"),
                .process("InApps/images/sound-wave-headphones.png"),
                .process("Inbox/images/ct_default_video.png"),
                .process("Inbox/images/ct_default_landscape_image.png"),
                .process("Inbox/images/ct_default_portrait_image.png"),
                .process("Inbox/images/placeholder.png"),
                .process("Inbox/images/volume_off.png"),
                .process("Inbox/images/volume_on.png"),
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
                .headerSearchPath("InApps/images"),
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
