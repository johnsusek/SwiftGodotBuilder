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
        .package(url: "https://github.com/migueldeicaza/SwiftGodot", revision: "a1af0de831a22a2f1d5d8b4221d9df2fdd12978f"),
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
