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
    .library(name: "VergeStore", targets: ["VergeStore"]),
    .library(name: "VergeViewModel", targets: ["VergeViewModel"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(name: "VergeStore", dependencies: []),
    .target(name: "VergeViewModel", dependencies: []),
  ]
)
