// swift-tools-version:5.9

import PackageDescription

_ = Package(name: "antimony",
            platforms: [
              .macOS(.v12),
            ],
            products: [
              .executable(name: "sb", targets: ["sb"])
            ],
            dependencies: [
              .package(url: "https://github.com/apple/swift-argument-parser",
                       from: "1.2.0"),
              .package(url: "https://github.com/apple/swift-driver",
                       branch: "main"),
            ],
            targets: [
              .executableTarget(name: "sb", dependencies: [
                "antimony",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
              ], path: "Tools/sb"),
              .target(name: "antimony", dependencies: [
                .product(name: "SwiftDriver", package: "swift-driver"),
              ])
           ])
