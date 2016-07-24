import PackageDescription

let package = Package(
    name: "DipTests",
    dependencies: [
        .Package(url: "..", Version(4,6,1)),
    ]
)
