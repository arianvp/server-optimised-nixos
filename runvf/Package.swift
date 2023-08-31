// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "runvf",
  platforms: [
    .macOS(.v11)
    .macOS(.v12)
    .macOS(.v13)
  ],
  products: [
    .executable(name: "runvf", targets: ["runvf"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0")
  ],
  targets: [
    .executableTarget(
      name: "runvf",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ],
      swiftSettings: [])
  ]
)
