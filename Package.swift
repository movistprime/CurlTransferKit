// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CurlTransferKit",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .library(name: "CurlTransferKit", targets: ["CurlTransferKit"]),
    ],
    targets: [
        .target(
            name: "CCurlTransferKit",
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedLibrary("curl"),
            ]
        ),
        .target(
            name: "CurlTransferKit",
            dependencies: ["CCurlTransferKit"]
        ),
        .testTarget(
            name: "CurlTransferKitTests",
            dependencies: ["CurlTransferKit"]
        ),
    ]
)
