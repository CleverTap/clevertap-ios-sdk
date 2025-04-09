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
            url: "https://akashvercetti.s3.ap-south-1.amazonaws.com/CleverTapSDK-7.1.9.xcframework.zip",
            checksum: "4bd4297c2d1d9211e3ce6a0e719332bf1df5b5d34facfd1cf43c6de6879d111d"
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
            linkerSettings: [
                .linkedLibrary("sqlite3"),
                .linkedFramework("SDWebImage", .when(platforms: [.iOS]))
            ]
        )
    ]
)
