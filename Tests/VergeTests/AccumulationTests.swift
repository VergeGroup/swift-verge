import Verge
import XCTest

final class AccumulationTests: XCTestCase {

  func test() {

    let store = DemoStore()

    let exp = expectation(description: "count")
    exp.expectedFulfillmentCount = 2

    let sub = store.accumulate {

      $0.ifChanged(\.count).do { [weak self] value in
        let _ = self
        exp.fulfill()
      }

      $0.ifChanged(\.name).do { [weak self] value in
        let _ = self
        
      }

    }

    store.commit {
      $0.count += 1
    }

    wait(for: [exp])

    let _ = sub
  }

}
