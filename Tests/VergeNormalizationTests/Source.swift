import VergeNormalization
import XCTest

final class Tests: XCTestCase {

  func test_insert() {

    var storage = MyStorage()

    storage.performBatchUpdates { t in
      t.modifying.author.insert(.init(rawID: "M"))
    }

    XCTAssertEqual(storage.author.count, 1)

  }

}
