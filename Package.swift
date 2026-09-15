// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LocusCal",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "LocusCalCore", targets: ["LocusCalCore"]),
    ],
    targets: [
        .target(name: "LocusCalCore", path: "Sources/LocusCalCore"),
        .testTarget(name: "LocusCalCoreTests", dependencies: ["LocusCalCore"], path: "Tests/LocusCalCoreTests"),
    ]
)
