import XCTest
import Verge
import VergeMacros

final class ChangesTests: XCTestCase {

  func test_performance_keypath() {

    let changes = Changes<DemoState>.init(old: nil, new: .init())

    measure {
      for _ in 0..<1000 {
        changes.ifChanged(\.name) { _ in

        }
      }
    }

  }

  func test_performance_macro() {

    let changes = Changes<DemoState>.init(old: nil, new: .init())

    measure {
      for _ in 0..<1000 {
        changes.ifChanged(#keyPathMap(\.name))
      }
    }

  }

  func test_performance_closure() {

    let changes = Changes<DemoState>.init(old: nil, new: .init())

    measure {
      for _ in 0..<1000 {
        changes.ifChanged({ $0.name })
      }
    }

  }

  func testKeyPathMap() {

    let changes = Changes<DemoState>.init(old: nil, new: .init())

    let b = #keyPathMap(\DemoState.name, \.count)

    changes
      .ifChanged(#keyPathMap(\DemoState.name))
      .do { arg in

    }

    changes
      .ifChanged(#keyPathMap(\DemoState.name, \.count))
      .do { arg in

    }

    changes
      .ifChanged({ ($0.name, $0.count) })
      .do { arg in

      }

  }
}
