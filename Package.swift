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
            targets: ["CleverTapSDK"]),
        .library(
            name: "CleverTapLocation",
            targets: ["CleverTapLocation"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.11.1")
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
                .copy("AmazonRootCA1.cer"),
                .copy("PrivacyInfo.xcprivacy"),
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
                .headerSearchPath("InApps/Matchers/"),
                .headerSearchPath("InApps/CustomTemplates/"),
                .headerSearchPath("Inbox/"),
                .headerSearchPath("Inbox/cells"),
                .headerSearchPath("Inbox/config"),
                .headerSearchPath("Inbox/controllers"),
                .headerSearchPath("Inbox/models"),
                .headerSearchPath("Inbox/views"),
                .headerSearchPath("ProductExperiences/"),
                .headerSearchPath("Session/"),
                .headerSearchPath("Swizzling/"),
                .headerSearchPath("FileDownload/")
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
        ),
        .target(
            name: "CleverTapLocation",
            path: "CleverTapLocation",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("./"),
                .headerSearchPath("CleverTapLocation/"),
                .headerSearchPath("CleverTapLocation/Classes/"),
                .headerSearchPath("CleverTapLocation/Classes")
            ],
            linkerSettings: [
                .linkedFramework("CoreLocation")
                ]
        )
    ]
)
