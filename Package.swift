// swift-tools-version:5.1
import PackageDescription

let package = Package(
  name: "Verge",  
  platforms: [
    .macOS(.v10_12),
    .iOS(.v10),
    .tvOS(.v10),
    .watchOS(.v3)
  ],
  products: [
    .library(name: "VergeCore", targets: ["VergeCore"]),
    .library(name: "VergeStore", targets: ["VergeStore"]),
    .library(name: "VergeORM", targets: ["VergeORM"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(name: "VergeCore", dependencies: []),
    .target(name: "VergeStore", dependencies: ["VergeCore"]),
    .target(name: "VergeORM", dependencies: ["VergeCore", "VergeStore"]),
  ]
)
