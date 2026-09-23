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
        ),
        .executable(
            name: "DSStoreSweeper",
            targets: ["DSStoreSweeper"]
        )
    ],
    targets: [
        .target(
            name: "SweeperCore"
        ),
        .executableTarget(
            name: "DSStoreSweeper",
            dependencies: ["SweeperCore"]
        ),
        .testTarget(
            name: "SweeperCoreTests",
            dependencies: ["SweeperCore"]
        )
    ]
)
