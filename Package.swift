// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CleverTapSDK",
    platforms: [
        .iOS(.v9),
        .tvOS(.v9),
        .watchOS(.v2)
    ],
    products: [
        .library(
            name: "CleverTapSDK",
            targets: ["CleverTapSDKWrapper"]),
        .library(
            name: "CleverTapLocation",
            targets: ["CleverTapLocation"]
        ),
        .library(
            name: "CleverTapWatchOS",
            targets: ["CleverTapWatchOS"]
        )
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "CleverTapSDK",
            path: "Framework/CleverTapSDK.xcframework"
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
                "CleverTapSDK"
            ],
            path: "CleverTapSDKWrapper",
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),
        .target(
            name: "CleverTapWatchOS",
            dependencies: [],
            path: "CleverTapWatchOS",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("./"),
                .headerSearchPath("CleverTapWatchOS/")
            ]
        )
    ]
)
