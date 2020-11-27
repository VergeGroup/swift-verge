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
    .library(name: "Verge", targets: ["Verge"]),
    .library(name: "VergeORM", targets: ["VergeORM"]),
    .library(name: "VergeRx", targets: ["VergeRx"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.1.1")
  ],
  targets: [
    .target(name: "VergeObjcBridge", dependencies: []),
    .target(name: "Verge", dependencies: ["VergeObjcBridge"]),
    .target(name: "VergeORM", dependencies: ["Verge", "VergeObjcBridge"]),
    .target(name: "VergeRx", dependencies: ["Verge", "VergeObjcBridge", "RxSwift", "RxCocoa"]),
  ],
  swiftLanguageVersions: [.v5]
)
