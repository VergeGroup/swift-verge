import Verge
import XCTest

final class TransactionTests: XCTestCase {

  func testTransaction() async {

    struct MyKey: TransactionKey {
      static var defaultValue: String? {
        nil
      }
    }

    let store = AsyncStore<DemoState, Never>(initialState: .init())

    await store.commit {
      $0.markAsModified()
      $1[MyKey.self] = "first commit"
    }

    XCTAssertEqual(store.state._transaction[MyKey.self], "first commit")
  }

}
