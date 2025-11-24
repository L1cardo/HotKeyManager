// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HotKeyManager",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "HotKeyManager", targets: ["HotKeyManager"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Clipy/Sauce", branch: "master"),
    ],
    targets: [
        .target(
            name: "HotKeyManager",
            dependencies: [
                "Sauce",
            ],
            path: "Sources/HotKeyManager"
        ),
        .testTarget(
            name: "HotKeyManagerTests",
            dependencies: ["HotKeyManager", "Sauce"],
            path: "Tests/HotKeyManagerTests"
        ),
    ]
)
