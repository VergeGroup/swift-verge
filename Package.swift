// swift-tools-version:5.9
import PackageDescription
import CompilerPluginSupport

let package = Package(
  name: "Verge",
  platforms: [
    .macOS(.v11),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(name: "Verge", targets: ["Verge"]),
    .library(name: "VergeTiny", targets: ["VergeTiny"]),
    .library(name: "VergeNormalization", targets: ["VergeNormalization"]),
    .library(name: "VergeNormalizationDerived", targets: ["VergeNormalizationDerived"]),
    .library(name: "VergeRx", targets: ["VergeRx"]),
    .library(name: "VergeClassic", targets: ["VergeClassic"]),
    .library(name: "VergeMacros", targets: ["VergeMacros"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.0.0"),
    .package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.3.0"),
    .package(url: "https://github.com/apple/swift-atomics.git", from: "1.0.2"),
    .package(url: "https://github.com/FluidGroup/swift-collections", from: "1.1.0"),
    .package(url: "https://github.com/VergeGroup/swift-concurrency-task-manager", from: "1.1.0"),

    /// for testing
    .package(url: "https://github.com/nalexn/ViewInspector.git", from: "0.9.3"),
    .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-macro-testing.git", from: "0.2.1")
  ],
  targets: [

    // compiler plugin
    .macro(
      name: "VergeMacrosPlugin",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
      ]
    ),

    // macro exports
    .target(name: "VergeMacros", dependencies: ["VergeMacrosPlugin"]),

    .target(name: "VergeTiny", dependencies: []),
    .target(name: "VergeComparator"),
    .target(
      name: "Verge",
      dependencies: [
        "VergeMacros",
        "VergeComparator",
        .product(name: "Atomics", package: "swift-atomics"),
        .product(name: "DequeModule", package: "swift-collections"),
        .product(name: "ConcurrencyTaskManager", package: "swift-concurrency-task-manager"),
      ]
    ),
    .target(
      name: "VergeClassic",
      dependencies: [
        "VergeRx"
      ]
    ),
    .target(
      name: "VergeNormalization",
      dependencies: [
        "VergeMacros",
        "VergeComparator",
        .product(name: "HashTreeCollections", package: "swift-collections"),
      ]
    ),
    .target(
      name: "VergeNormalizationDerived",
      dependencies: [
        "Verge",
        "VergeNormalization",
        .product(name: "HashTreeCollections", package: "swift-collections"),
      ]
    ),
    .target(
      name: "VergeRx",
      dependencies: [
        "Verge",
        .product(name: "RxSwift", package: "RxSwift"),
        .product(name: "RxCocoa", package: "RxSwift"),
      ]
    ),
    .testTarget(
      name: "VergeClassicTests",
      dependencies: ["VergeClassic"]
    ),
    .testTarget(
      name: "VergeNormalizationTests",
      dependencies: ["VergeNormalization"]
    ),
    .testTarget(
      name: "VergeNormalizationDerivedTests",
      dependencies: ["VergeNormalizationDerived"]
    ),
    .testTarget(
      name: "VergeRxTests",
      dependencies: ["VergeRx", "VergeClassic"]
    ),
    .testTarget(
      name: "VergeTests",
      dependencies: ["Verge", "ViewInspector"]
    ),
    .testTarget(
      name: "VergeTinyTests",
      dependencies: ["VergeTiny"]
    ),
    .testTarget(name: "VergeMacrosTests", dependencies: [
      "VergeMacrosPlugin",
      .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      .product(name: "MacroTesting", package: "swift-macro-testing"),
    ])
  ],
  swiftLanguageVersions: [.v5]
)
