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

    await store.backgroundCommit {
      $1[MyKey.self] = "first commit"
    }

  }

}
