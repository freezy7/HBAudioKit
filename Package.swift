// swift-tools-version:5.5

import PackageDescription

let package = Package (
    name: "HBAudioKit",
    platforms: [.macOS(.v11), .iOS(.v13), .tvOS(.v13)],
    products: [
        .library(name: "HBAudioKit", targets: ["HBAudioKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/freezy7/libmp3lame", from: "3.100.0")
    ],
    targets: [
        .target(
            name: "HBAudioKit",
            dependencies: ["libmp3lame"],
            path: "Classes/AudioKit",
            publicHeadersPath: "PublicHeaders",
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("c++"),
                .linkedFramework("UIKit"),
                .linkedFramework("Foundation"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("algorithm"),
                .linkedFramework("Accelerate"),
            ]
        )
    ]
)
