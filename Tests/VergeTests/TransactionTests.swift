import Verge
import XCTest

final class TransactionTests: XCTestCase {

  func testTransaction() async {

    struct MyKey: TransactionKey {
      static var defaultValue: String? {
        nil
      }
    }

    let store = Store<DemoState, Never>(initialState: .init())

    await store.commit {
      $0.count += 1
      $1[MyKey.self] = "first commit"
    }

    XCTAssertEqual(store.state._transaction[MyKey.self], "first commit")
  }

}
