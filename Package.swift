// swift-tools-version: 6.0
#if canImport(PackageDescription)
import PackageDescription

let package = Package(
    name: "CamperToolsCore",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "CamperToolsCore", targets: ["CamperToolsCore"])
    ],
    targets: [
        .target(
            name: "CamperToolsCore",
            path: "Managers",
            exclude: [
                "FlashlightManager.swift",
                "LocationManager.swift",
                "MotionManager.swift",
                "ShakeGesture.swift",
                "StoreManager.swift"
            ],
            sources: [
                "UnitFormatting.swift",
                "ShimCalculator.swift",
                "WeatherHelper.swift",
                "WeatherService.swift"
            ]
        ),
        .testTarget(
            name: "CamperToolsCoreTests",
            dependencies: ["CamperToolsCore"],
            path: "Tests/CamperToolsCoreTests"
        )
    ]
)
#endif
