import Verge
import XCTest

final class AccumulationTests: XCTestCase {

  func test() {

    let store = DemoStore()

    let expForCount = expectation(description: "count")
    expForCount.expectedFulfillmentCount = 2

    let expForName = expectation(description: "name")
    expForName.expectedFulfillmentCount = 2

    let sub = store.accumulate { [weak self] in

      $0.ifChanged(\.count).do { value in
        expForCount.fulfill()
        runMain()
      }

      $0.ifChanged(\.name).do { value in
        expForName.fulfill()
      }

    }

    store.commit {
      $0.count += 1
    }

    store.commit {
      $0.name = "name"
    }

    wait(for: [expForCount, expForName], timeout: 1)

    let _ = sub
  }

}

@MainActor
private func runMain() {

}
