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
            targets: ["CleverTapSDKWrapper"]),
        .library(
            name: "CleverTapLocation",
            targets: ["CleverTapLocation"]
        )
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "SDWebImage",
            url: "https://github.com/SDWebImage/SDWebImage/releases/download/5.21.0/SDWebImage-dynamic.xcframework.zip",
            checksum: "e034ea04f5e86866bc3081d009941bd5b2a2ed705b3a06336656484514116638"
        ),
        .binaryTarget(
            name: "CleverTapSDK",
            url: "https://github.com/CleverTap/clevertap-ios-sdk/releases/download/untagged-9faef5147bd252dc39bc/CleverTapSDK.xcframework.zip",
            checksum: "ea7a2a3facfcd94073c354b4d3c79bfd2a663b9b53a8855d68d4e40ca90f5b95"
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
        ),
        .target(
            name: "CleverTapSDKWrapper",
            dependencies: [
                "CleverTapSDK",
                "SDWebImage"
            ],
            path: "CleverTapSDKWrapper",
            // TODO: Will remove linkerSettings if not needed
            linkerSettings: [
                .linkedLibrary("sqlite3"),
                .linkedLibrary("c++"),
                .linkedLibrary("z"),
                .linkedFramework("SDWebImage", .when(platforms: [.iOS]))
            ]
        )
    ]
)
