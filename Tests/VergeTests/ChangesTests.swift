import XCTest
import Verge
import VergeMacros

final class ChangesTests: XCTestCase {

  func test_performance_keypath() {

    let changes = Changes<DemoState>.init(old: nil, new: .init())

    measure {
      for _ in 0..<1000 {
        changes.ifChanged(\.name).do { _ in

        }
      }
    }

  }

  func test_performance_macro() {

    let changes = Changes<DemoState>.init(old: nil, new: .init())

    measure {
      for _ in 0..<1000 {
        _ = changes.ifChanged(#keyPathMap(\.name))
      }
    }

  }

  func test_performance_closure() {

    let changes = Changes<DemoState>.init(old: nil, new: .init())

    measure {
      for _ in 0..<1000 {
        _ = changes.ifChanged({ $0.name })
      }
    }

  }

  func test_same() {

    let changes = Changes<DemoState>.init(old: .init(), new: .init())

    changes
      .ifChanged(#keyPathMap(\.name))
      .do { arg in
        XCTFail()
    }

    changes
      .ifChanged(#keyPathMap(\.name, \.count))
      .do { arg in
        XCTFail()
    }

    changes
      .ifChanged({ $0.name })
      .do { arg in
        XCTFail()
      }

    changes
      .ifChanged({ ($0.name, $0.count) })
      .do { arg in
        XCTFail()
      }

  }

  func test_diff() {

    let changes = Changes<DemoState>.init(
      old: .init(name: "---"),
      new: .init()
    )

    var hit = false

    changes
      .ifChanged({ ($0.name, $0.count) })
      .do { arg in
        hit = true
      }

    XCTAssertTrue(hit)
  }
}
