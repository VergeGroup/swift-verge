// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "VergeStore",
    products: [
        .library(name: "VergeStore", targets: ["VergeStore"]),
    ],
    dependencies: [
    ],
    targets: [       
        .target(name: "VergeStore", dependencies: []),
    ]
)
