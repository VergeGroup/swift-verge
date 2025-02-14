import XCTest
import VergeNormalizationDerived

final class CombiningTests: XCTestCase {

  func test_combine() {

    let store = Store<DemoState, Never>(
      initialState: .init()
    )

    struct View: Equatable {
      var book: Book?
      var author: Author?
    }

    let derived = store.normalizedStorage(.keyPath(\.db)).derived { storage in
      View(
        book: storage.book.find(by: .init("1")),
        author: storage.author.find(by: .init("1"))
      )
    }

    let exp = expectation(description: "call")
    exp.expectedFulfillmentCount = 3

    let sub = derived.sinkState { view in
      exp.fulfill()
    }

    store.commit {
      $0.db.performBatchUpdates { t in
        t.modifying.book.insert(Book(rawID: "1", authorID: .init("1")))
        t.modifying.author.insert(Author(rawID: "1", name: "Hiroshi"))
      }
    }

    // no affects
    store.commit {
      $0.count += 1
    }

    _ = store.commit {
      $0.db.performBatchUpdates { t in
        t.modifying.author.insert(Author(rawID: "1", name: "Hiroshi Kimura"))
      }
    }

    wait(for: [exp], timeout: 10)

    XCTAssertEqual(derived.state.author?.name, "Hiroshi Kimura")

    _ = sub
  }
}

