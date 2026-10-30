// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "CleverTapSDK",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v9)
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
            name: "SDWebImageCT",
            url: "https://github.com/SDWebImage/SDWebImage/releases/download/5.21.0/SDWebImage-dynamic.xcframework.zip",
            checksum: "e034ea04f5e86866bc3081d009941bd5b2a2ed705b3a06336656484514116638"
        ),
        .binaryTarget(
            name: "CleverTapSDK",
            url: "https://d1new0xr8otir0.cloudfront.net/CleverTapSDK-7.9.1.xcframework.zip",
            checksum: "2f4a5f1930deefa9fb693e837ea13dc05804f599d96fec8fc6acff696b131319"
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
                .target(name: "SDWebImageCT", condition: .when(platforms: [.iOS]))
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
