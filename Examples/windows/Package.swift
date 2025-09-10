// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "MyGame",
  products: [
      .library(name: "MyGame", type: .dynamic, targets: ["MyGame"]),
  ],
  dependencies: [
    .package(url: "https://github.com/migueldeicaza/SwiftGodot", revision: "20d2d7a35d2ad392ec556219ea004da14ab7c1d4"),
    .package(url: "https://github.com/johnsusek/SwiftGodotBuilder", branch: "main")
  ],
  targets: [
    .target(name: "MyGame", dependencies: ["SwiftGodot", "SwiftGodotBuilder"]),
  ]
)

