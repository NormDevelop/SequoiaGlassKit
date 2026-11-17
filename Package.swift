// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SequoiaGlassKit",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "SequoiaGlassKit", targets: ["SequoiaGlassKit"]),
        .library(name: "SequoiaGlassMetal", targets: ["SequoiaGlassMetal"]),
        .executable(name: "GlassNativeLab", targets: ["GlassNativeLab"])
    ],
    targets: [
        // Default: native Apple blur/vibrancy, zero screen capture, zero Metal work.
        .target(name: "SequoiaGlassKit", linkerSettings: [
            .linkedFramework("AppKit"), .linkedFramework("QuartzCore")
        ]),
        // Optional, linked only by apps rendering their own Metal source pixels.
        .target(name: "SequoiaGlassMetal", dependencies: ["SequoiaGlassKit"],
                linkerSettings: [
                    .linkedFramework("Metal"), .linkedFramework("MetalKit")
                ]),
        .executableTarget(name: "GlassNativeLab", dependencies: ["SequoiaGlassKit"]),
        .testTarget(name: "SequoiaGlassKitTests", dependencies: ["SequoiaGlassKit"])
    ]
)
