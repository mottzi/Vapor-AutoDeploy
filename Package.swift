// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "mottzi",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.4.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "Crypto", package: "swift-crypto"),
            ],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v5]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableExperimentalFeature("StrictConcurrency"),
] }
