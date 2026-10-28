// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Yijian",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Yijian", targets: ["Yijian"])],
    targets: [
        .target(name: "YijianCore"),
        .executableTarget(name: "Yijian", dependencies: ["YijianCore"]),
        .testTarget(name: "YijianCoreTests", dependencies: ["YijianCore"])
    ]
)
