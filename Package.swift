// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "pterm",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        // C module: VT parser, ring buffer, UTF-8 decoder, Tracy bridge
        .target(
            name: "PtermCore",
            path: "Sources/PtermCore",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
                .headerSearchPath("tracy"),  // Tracy public headers (symlink to ../../tracy/public/tracy)
                .unsafeFlags(["-DTRACY_ENABLE", "-DTRACY_AUTOCAPTURE=1"]),
                .unsafeFlags(["-Wall", "-Wextra", "-Werror", "-O2"], .when(configuration: .release)),
                .unsafeFlags(["-Wall", "-Wextra", "-Werror", "-g"], .when(configuration: .debug))
            ],
            linkerSettings: [
                .unsafeFlags(["-L/Volumes/External/Code/tracy/build", "-lTracyClient", "-lc++"]),
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "/Volumes/External/Code/tracy/build"])
            ]
        ),
        // Main Swift executable
        .executableTarget(
            name: "PtermApp",
            dependencies: ["PtermCore"],
            path: "Sources/PtermApp",
            exclude: [
                "Rendering/Shaders/terminal.metal"
            ],
            cSettings: [
                .headerSearchPath("../PtermCore/include")
            ],
            swiftSettings: [
                .unsafeFlags(["-O"], .when(configuration: .release))
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("CoreText"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("Security"),
                .linkedFramework("UserNotifications"),
                .linkedFramework("AVFoundation"),
                .unsafeFlags(["-L/Volumes/External/Code/tracy/build", "-lTracyClient", "-lc++"]),
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "/Volumes/External/Code/tracy/build"])
            ]
        ),
        // C module tests
        .testTarget(
            name: "PtermCoreTests",
            dependencies: ["PtermCore"]
        ),
        // Swift module tests
        .testTarget(
            name: "PtermAppTests",
            dependencies: ["PtermApp"]
        )
    ]
)
