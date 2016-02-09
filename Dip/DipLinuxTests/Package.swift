import PackageDescription

let package = Package(
        name: "DipLinuxTests",
        targets: [],
        dependencies: [
                .Package(url: "https://github.com/AliSoftware/Dip", majorVersion: 4, minor: 2),
        ]
)

