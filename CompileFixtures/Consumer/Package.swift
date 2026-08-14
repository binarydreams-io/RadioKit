// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "RadioKitConsumer",
  platforms: [.macOS(.v14)],
  dependencies: [
    .package(name: "RadioKit", path: "../.."),
  ],
  targets: [
    .executableTarget(
      name: "RadioKitConsumer",
      dependencies: [.product(name: "RadioKit", package: "RadioKit")]
    ),
  ]
)
