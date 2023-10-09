import Verge
import XCTest

final class StoreMapTests: XCTestCase {

  @MainActor
  func testBasic() {

    let store = Store<DemoState, Never>(initialState: .init())

    let countState = store.map(\.count)

    var exp = expectation(description: "")
    exp.expectedFulfillmentCount = 2

    let s = countState.sinkState { state in
      exp.fulfill()
    }

    // cause update
    store.commit {
      $0.count += 1
    }

    // won't cause update
    store.commit {
      $0.count = 1
    }

    wait(for: [exp])

    withExtendedLifetime(s, {})

  }

}
