// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DSStoreSweeper",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SweeperCore",
            targets: ["SweeperCore"]
        )
    ],
    targets: [
        .target(
            name: "SweeperCore"
        ),
        .testTarget(
            name: "SweeperCoreTests",
            dependencies: ["SweeperCore"]
        )
    ]
)
