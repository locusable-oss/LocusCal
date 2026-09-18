// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LocusCal",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "LocusCalCore", targets: ["LocusCalCore"]),
    ],
    targets: [
        .target(name: "LocusCalCore", path: "Sources/LocusCalCore"),
        .testTarget(name: "LocusCalCoreTests", dependencies: ["LocusCalCore"], path: "Tests/LocusCalCoreTests"),
    ]
)
