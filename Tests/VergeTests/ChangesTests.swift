import XCTest
import Verge
import VergeMacros

final class ChangesTests: XCTestCase {

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
