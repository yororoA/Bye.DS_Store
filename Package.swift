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
    dependencies: [
        .package(
            url: "https://github.com/gonzalezreal/swift-markdown-ui",
            from: "2.4.1"
        )
    ],
    targets: [
        .target(
            name: "SweeperCore"
        ),
        .executableTarget(
            name: "DSStoreSweeper",
            dependencies: [
                "SweeperCore",
                .product(
                    name: "MarkdownUI",
                    package: "swift-markdown-ui"
                )
            ]
        ),
        .testTarget(
            name: "SweeperCoreTests",
            dependencies: ["SweeperCore"]
        ),
        .testTarget(
            name: "DSStoreSweeperTests",
            dependencies: ["DSStoreSweeper"]
        )
    ]
)
