// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "HBAudioKit",
    platforms: [.macOS(.v11), .iOS(.v13), .tvOS(.v13)],
    products: [.library(name: "HBAudioKit", targets: ["HBAudioKit"])],
    targets: [
        .target(
            name: "HBAudioKit",
            path: "Classes",
//            sources: [
//                "HBAKNode.h", "HBAKNode.m",
//                "HBAKMixer.h", "HBAKMixer.m",
//            ],
            publicHeadersPath: "AudioKit/PublicHeaders",
            linkerSettings: [.linkedLibrary("z"), .linkedLibrary("c++")]
        )
    ]
)
