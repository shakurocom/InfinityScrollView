// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InfinityScrollView",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "InfinityScrollView",
            targets: ["InfinityScrollView"]),
    ],
    dependencies: [
        .package(url: "https://github.com/shakurocom/CommonTypes.git", from: "1.9.6"),
    ],
    targets: [
        .target(
            name: "InfinityScrollView",
            dependencies: [
                .product(name: "CommonTypes", package: "CommonTypes"),
            ],
            path: "Source"),
    ]
)
