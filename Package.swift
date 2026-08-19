// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Teleprompter",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Teleprompter",
            path: "Sources/Teleprompter"
        )
    ]
)
