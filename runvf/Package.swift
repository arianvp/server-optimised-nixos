// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "runvf",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "runvf", targets: ["runvf"]),
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(name: "runvf",
                dependencies: [ ],
                swiftSettings: []),
    ]
)