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
            dependencies: ["SDWebImage"],
            path: "Sources/CleverTap/",
            resources: [
                .copy("CleverTapSDK/DigiCertGlobalRootCA.crt"),
                .copy("CleverTapSDK/DigiCertSHA2SecureServerCA.crt"),
                .process("CleverTapSDK/ios.modulemap"),
                .process("CleverTapSDK/tvos.modulemap"),
                .process("CleverTapSDK/InApps/images/ic_expand@1x.png"),
                .process("CleverTapSDK/InApps/images/ic_expand@2x.png"),
                .process("CleverTapSDK/InApps/images/ic_expand@3x.png"),
                .process("CleverTapSDK/InApps/images/ic_pause@1x.png"),
                .process("CleverTapSDK/InApps/images/ic_pause@2x.png"),
                .process("CleverTapSDK/InApps/images/ic_pause@3x.png"),
                .process("CleverTapSDK/InApps/images/ic_play@1x.png"),
                .process("CleverTapSDK/InApps/images/ic_play@2x.png"),
                .process("CleverTapSDK/InApps/images/ic_play@3x.png"),
                .process("CleverTapSDK/InApps/images/ic_shrink@1x.png"),
                .process("CleverTapSDK/InApps/images/ic_shrink@2x.png"),
                .process("CleverTapSDK/InApps/images/ic_shrink@3x.png"),
                .process("CleverTapSDK/InApps/images/ic_thumb.png"),
                .process("CleverTapSDK/InApps/images/sound-wave-headphones.png"),
                .process("CleverTapSDK/Inbox/images/ct_default_video.png"),
                .process("CleverTapSDK/Inbox/images/ct_default_landscape_image.png"),
                .process("CleverTapSDK/Inbox/images/ct_default_portrait_image.png"),
                .process("CleverTapSDK/Inbox/images/placeholder.png"),
                .process("CleverTapSDK/Inbox/images/volume_off.png"),
                .process("CleverTapSDK/Inbox/images/volume_on.png")
            ],
            cSettings: [
                .headerSearchPath("CleverTapSDK"),
                .headerSearchPath("CleverTapSDK/ABTesting/"),
                .headerSearchPath("CleverTapSDK/ABTesting/controllers"),
                .headerSearchPath("CleverTapSDK/ABTesting/models"),
                .headerSearchPath("CleverTapSDK/ABTesting/uieditor/"),
                .headerSearchPath("CleverTapSDK/ABTesting/uieditor/messages"),
                .headerSearchPath("CleverTapSDK/ABTesting/uieditor/serializers"),
                .headerSearchPath("CleverTapSDK/ABTesting/uieditor/transformers"),
                .headerSearchPath("CleverTapSDK/ABTesting/uieditor/websocket"),
                .headerSearchPath("CleverTapSDK/ABTesting/utils"),
                .headerSearchPath("CleverTapSDK/DisplayUnit/"),
                .headerSearchPath("CleverTapSDK/DisplayUnit/controllers"),
                .headerSearchPath("CleverTapSDK/DisplayUnit/models"),
                .headerSearchPath("CleverTapSDK/FeatureFlags/"),
                .headerSearchPath("CleverTapSDK/FeatureFlags/controllers"),
                .headerSearchPath("CleverTapSDK/FeatureFlags/models"),
                .headerSearchPath("CleverTapSDK/InApps/"),
                .headerSearchPath("CleverTapSDK/InApps/images"),
                .headerSearchPath("CleverTapSDK/Inbox/"),
                .headerSearchPath("CleverTapSDK/Inbox/cells"),
                .headerSearchPath("CleverTapSDK/Inbox/config"),
                .headerSearchPath("CleverTapSDK/Inbox/controllers"),
                .headerSearchPath("CleverTapSDK/Inbox/images"),
                .headerSearchPath("CleverTapSDK/Inbox/models"),
                .headerSearchPath("CleverTapSDK/Inbox/views"),
                .headerSearchPath("CleverTapSDK/ProductConfig/"),
                .headerSearchPath("CleverTapSDK/ProductConfig/models"),
                .headerSearchPath("CleverTapSDK/ProductConfig/controllers")
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
        ),
        .testTarget(
            name: "CleverTapTests",
            dependencies: ["CleverTap"]
        ),
    ]
)
