
import Verge
import XCTest

final class IsolatedStoreTests: XCTestCase {

  @MainActor
  func test_mainActorStore_in_mainActor() {

    let store = MainActorStore<_, Never>(initialState: DemoState())

    store.commit {
      $0.count += 1
    }

    XCTAssertEqual(store.state.count, 1)

  }

  func test_async() {

  }

}
