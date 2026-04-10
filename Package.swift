// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "IconKit",
    products: [
        .library(name: "IconKit", targets: ["IconKit"]),
        .executable(name: "iconkit", targets: ["IconKitCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        .target(name: "IconKit"),
        .executableTarget(
            name: "IconKitCLI",
            dependencies: [
                "IconKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(name: "IconKitTests", dependencies: ["IconKit"]),
    ]
)
