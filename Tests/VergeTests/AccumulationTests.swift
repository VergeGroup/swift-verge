import Verge
import XCTest

final class AccumulationTests: XCTestCase {

  func test_main() {

    let store = DemoStore()

    let expForCount = expectation(description: "count")
    expForCount.expectedFulfillmentCount = 2

    let expForName = expectation(description: "name")
    expForName.expectedFulfillmentCount = 2

    let sub = store.accumulate(queue: .mainIsolated()) { [weak self] in

      $0.ifChanged(\.count).do { value in
        expForCount.fulfill()
        runMain()
      }

      $0.ifChanged(\.name).do { value in
        expForName.fulfill()
      }

      // checks for result builders
      if let _ = self {
        $0.ifChanged(\.name).do { value in
          runMain()
        }
      }

      // checks for result builders
      if true {
        $0.ifChanged(\.name).do { value in
          runMain()
        }
      } else {
        $0.ifChanged(\.name).do { value in
          runMain()
        }
      }

      // checks for result builders
      if true {
        $0.ifChanged(\.name).do { value in
          runMain()
        }
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

  func test_background() {

    let store = DemoStore()

    let expForCount = expectation(description: "count")
    expForCount.expectedFulfillmentCount = 2

    let expForName = expectation(description: "name")
    expForName.expectedFulfillmentCount = 2

    let sub = store.accumulate(queue: .passthrough) { [weak self] in

      $0.ifChanged(\.count).do { value in
        expForCount.fulfill()
      }

      $0.ifChanged(\.name).do { value in
        expForName.fulfill()
      }

      // checks for result builders
      if let _ = self {
        $0.ifChanged(\.name).do { value in
        }
      }

      // checks for result builders
      if true {
        $0.ifChanged(\.name).do { value in
        }
      } else {
        $0.ifChanged(\.name).do { value in
        }
      }

      // checks for result builders
      if true {
        $0.ifChanged(\.name).do { value in
        }
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
