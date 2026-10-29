// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Ice",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Ice", path: "Sources/Ice"),
    ]
)
