// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "YourGPTSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "YourGPTSDK",
            targets: ["YourGPTSDK"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "YourGPTSDK",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "YourGPTSDKTests",
            dependencies: ["YourGPTSDK"],
            path: "Tests"
        ),
    ]
)