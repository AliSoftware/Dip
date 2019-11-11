// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Dip",
    products: [
        .library(name: "Dip", targets: ["Dip"]),
    ],
    targets: [
        .target(name: "Dip", dependencies: [], path: "Sources"),
        .testTarget(name: "DipTests", dependencies: ["Dip"], path: "Tests"),
    ]
)

