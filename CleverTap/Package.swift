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
                .process("ios.modulemap"),
                .process("tvos.modulemap"),
                .copy("DigiCertGlobalRootCA.crt"),
                .copy("DigiCertSHA2SecureServerCA.crt")
            ],
            cSettings: [
                .headerSearchPath("CleverTapSDK"),
                .headerSearchPath("CleverTapSDK/ABTesting/"),
                .headerSearchPath("CleverTapSDK/ABTesting/controllers"),
                .headerSearchPath("CleverTapSDK/ABTesting/models"),
                .headerSearchPath("CleverTapSDK/ABTesting/uieditor/"),
                .headerSearchPath("CleverTapSDK/ABTesting/uieditor/messages"),
                .headerSearchPath("CleverTapSDK/ABTesting/uieditor/websocket"),
                .headerSearchPath("CleverTapSDK/ABTesting/uieditor/serializers"),
                .headerSearchPath("CleverTapSDK/ABTesting/uieditor/transformers"),
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
            ]
//            ,
//            linkerSettings: [
//                .linkedFramework("libsqlite3.tbd"),
//                .linkedFramework("libicucore.tbd")
//            ]
        ),
        .testTarget(
            name: "CleverTapTests",
            dependencies: ["CleverTap"]
        ),
    ]
)
