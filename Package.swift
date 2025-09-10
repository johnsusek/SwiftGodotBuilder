// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SwiftGodotBuilder",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SwiftGodotBuilder", targets: ["SwiftGodotBuilder"]),
        .plugin(name: "GenNodeApi", targets: ["GenNodeApi"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
        .package(url: "https://github.com/migueldeicaza/SwiftGodot", revision: "20d2d7a35d2ad392ec556219ea004da14ab7c1d4"),
        .package(url: "https://github.com/johnsusek/SwiftGodotPatterns", branch: "main"),
        // .package(path: "../SwiftGodotPatterns"),
    ],
    targets: [
        // Codegen tool that reads extension_api.json and writes GeneratedGNodeAliases.swift
        .executableTarget(name: "NodeApiGen", path: "Sources/NodeApiGen"),

        // Build-tool plugin that invokes NodeApiGen every build.
        .plugin(
            name: "GenNodeApi",
            capability: .buildTool(),
            dependencies: ["NodeApiGen"]
        ),

        .target(
            name: "SwiftGodotBuilder",
            dependencies: ["SwiftGodot", "SwiftGodotPatterns"],
            plugins: ["GenNodeApi"]
        ),

        .testTarget(
            name: "SwiftGodotBuilderTests",
            dependencies: ["SwiftGodotBuilder"]
        ),
    ]
)
