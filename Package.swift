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
    .library(name: "VergeRx", targets: ["VergeRx"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.1.1")
  ],
  targets: [
    .target(name: "VergeObjcBridge", dependencies: []),
    .target(name: "VergeCore", dependencies: ["VergeObjcBridge"]),
    .target(name: "VergeStore", dependencies: ["VergeCore", "VergeObjcBridge"]),
    .target(name: "VergeORM", dependencies: ["VergeCore", "VergeStore", "VergeObjcBridge"]),
    .target(name: "VergeRx", dependencies: ["VergeCore", "VergeStore", "VergeObjcBridge", "RxSwift", "RxCocoa"]),
  ],
  swiftLanguageVersions: [.v5]
)
