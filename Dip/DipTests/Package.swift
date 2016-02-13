import PackageDescription

let package = Package(
        name: "DipTests",
        dependencies: [
                .Package(url: "../../../Dip", majorVersion: 4, minor: 2),
        ]
)

