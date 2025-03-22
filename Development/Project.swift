import ProjectDescription

let project = Project(
  name: "Development",
  targets: [
    .target(
      name: "Development",
      destinations: .iOS,
      product: .app,
      bundleId: "io.tuist.Development",
      infoPlist: .extendingDefault(
        with: [
          "UILaunchScreen": [
            "UIColorName": "",
            "UIImageName": "",
          ]
        ]
      ),
      sources: ["Development/Sources/**"],
      resources: ["Development/Resources/**"],
      dependencies: [
        .external(name: "Verge")
      ]
    ),
    .target(
      name: "DevelopmentUITests",
      destinations: .iOS,
      product: .uiTests,
      bundleId: "io.tuist.DevelopmentUITests",
      infoPlist: .default,
      sources: ["Development/UITests/**"],
      resources: [],
      dependencies: [.target(name: "Development")]
    ),
    .target(
      name: "DevelopmentTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "io.tuist.DevelopmentTests",
      infoPlist: .default,
      sources: ["Development/Tests/**"],
      resources: [],
      dependencies: [.target(name: "Development")]
    ),
  ]
)
