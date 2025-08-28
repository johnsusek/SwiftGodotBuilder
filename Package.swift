// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SwiftGodotBuilder",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "SwiftGodotBuilder",
            targets: ["SwiftGodotBuilder"]
        ),
    ],
    dependencies: [
        // .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
        .package(url: "https://github.com/migueldeicaza/SwiftGodot", revision: "20d2d7a35d2ad392ec556219ea004da14ab7c1d4"),
    ],
    targets: [
        .target(
            name: "SwiftGodotBuilder",
            dependencies: ["SwiftGodot"]
        ),
        .testTarget(
            name: "SwiftGodotBuilderTests",
            dependencies: ["SwiftGodotBuilder"]
        ),
    ]
)
