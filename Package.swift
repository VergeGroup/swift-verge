// swift-tools-version:5.6
import PackageDescription

let package = Package(
  name: "Verge",
  platforms: [
    .macOS(.v10_12),
    .iOS(.v11),
    .tvOS(.v10),
    .watchOS(.v3),
  ],
  products: [
    .library(name: "Verge", targets: ["Verge"]),
    .library(name: "VergeTiny", targets: ["VergeTiny"]),
    .library(name: "VergeORM", targets: ["VergeORM"]),
    .library(name: "VergeRx", targets: ["VergeRx"]),
    .library(name: "VergeClassic", targets: ["VergeClassic"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.0.0"),
    .package(url: "https://github.com/apple/swift-docc-plugin.git", branch: "main"),
  ],
  targets: [
    .target(name: "VergeObjcBridge", dependencies: []),
    .target(name: "VergeTiny", dependencies: []),
    .target(name: "Verge", dependencies: ["VergeObjcBridge"]),
    .target(name: "VergeClassic", dependencies: ["RxSwift", "RxCocoa", "VergeObjcBridge", "VergeRx"]),
    .target(name: "VergeORM", dependencies: ["Verge", "VergeObjcBridge"]),
    .target(
      name: "VergeRx",
      dependencies: [
        "Verge",
        "VergeObjcBridge",
        .product(name: "RxSwift", package: "RxSwift"),
        .product(name: "RxCocoa", package: "RxSwift")
      ]
    ),
  ],
  swiftLanguageVersions: [.v5]
)
