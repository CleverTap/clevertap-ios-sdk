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
            url: "https://github.com/CleverTap/clevertap-ios-sdk/releases/download/8.0.2/CleverTapSDK.xcframework.zip",
            checksum: "df4625b4b34ca18af264a5a2176dd33a60e9dfbd7563b26efb05671e759395c3"
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
