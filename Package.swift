// swift-tools-version:5.6
import PackageDescription

let package = Package(
  name: "Verge",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(name: "Verge", targets: ["Verge"]),
    .library(name: "VergeTaskManager", targets: ["VergeTaskManager"]),
    .library(name: "VergeTiny", targets: ["VergeTiny"]),
    .library(name: "VergeORM", targets: ["VergeORM"]),
    .library(name: "VergeRx", targets: ["VergeRx"]),
    .library(name: "VergeClassic", targets: ["VergeClassic"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.0.0"),
    .package(url: "https://github.com/apple/swift-docc-plugin.git", branch: "main"),
    .package(url: "https://github.com/apple/swift-atomics.git", from: "1.0.2"),
  ],
  targets: [
    .target(
      name: "VergeTaskManager",
      dependencies: [.product(name: "Atomics", package: "swift-atomics")]
    ),
    .target(name: "VergeObjcBridge", dependencies: []),
    .target(name: "VergeTiny", dependencies: []),
    .target(name: "Verge", dependencies: ["VergeObjcBridge"]),
    .target(
      name: "VergeClassic",
      dependencies: [
        "VergeObjcBridge",
        "VergeRx",
      ]
    ),
    .target(name: "VergeORM", dependencies: ["Verge", "VergeObjcBridge"]),
    .target(
      name: "VergeRx",
      dependencies: [
        "Verge",
        "VergeObjcBridge",
        .product(name: "RxSwift", package: "RxSwift"),
        .product(name: "RxCocoa", package: "RxSwift"),
      ]
    ),
    //    .testTarget(name: "AsyncVergeTests", dependencies: ["AsyncVerge"]),
    .testTarget(name: "VergeTaskManagerTests", dependencies: ["VergeTaskManager"]),
    .testTarget(name: "VergeClassicTests", dependencies: ["VergeClassic"]),
    .testTarget(name: "VergeORMTests", dependencies: ["VergeORM"]),
    .testTarget(name: "VergeRxTests", dependencies: ["VergeRx", "VergeClassic", "VergeORM"]),
    .testTarget(name: "VergeTests", dependencies: ["Verge"]),
    .testTarget(name: "VergeTinyTests", dependencies: ["VergeTiny"]),
  ],
  swiftLanguageVersions: [.v5]
)
