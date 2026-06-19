// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Textream",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Textream",
            path: "Textream/Textream",
            exclude: ["Assets.xcassets", "Fonts", "icon.svg", "Textream.entitlements"]
        )
    ]
)
