import Verge
import XCTest

final class TransactionTests: XCTestCase {

  func testTransaction() {

    struct MyKey: TransactionKey {
      static var defaultValue: String? {
        nil
      }
    }

    let store = DemoStore()

    store.commit {
      $0._transaction[MyKey.self] = "first commit"
      $0.markAsModified()
    }

    XCTAssertEqual(store.state._transaction[MyKey.self], "first commit")
  }

}
