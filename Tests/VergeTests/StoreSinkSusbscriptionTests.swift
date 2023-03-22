
import XCTest
import Verge

final class StoreSinkSubscriptionTests: XCTestCase {

  func testStore() {

    var store: DemoStore? = DemoStore()
    weak var weakStore: DemoStore? = store

    store!.sinkState { _ in

    }
    .withSource()

    XCTAssertNotNil(weakStore)

    store = nil

    XCTAssertNotNil(weakStore)
    XCTAssertNil(weakStore)
  }

}
