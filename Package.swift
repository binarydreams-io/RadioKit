// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "RadioKit",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
  ],
  products: [
    .library(
      name: "RadioKit",
      targets: ["RadioKit"]
    )
  ],
  targets: [
    .target(
      name: "RadioKit",
      resources: [
        .process("PrivacyInfo.xcprivacy"),
        .copy("VERSION"),
      ]
    ),
    .testTarget(
      name: "RadioKitTests",
      dependencies: ["RadioKit"]
    ),
  ]
)
