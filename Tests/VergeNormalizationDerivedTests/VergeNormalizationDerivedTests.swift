import VergeNormalizationDerived
import XCTest
import os.lock

extension Store where State == DemoState {

  var database: NormalizedStoragePath<Store, DemoState.DatabaseSelector> {
    return .init(store: self, storageSelector: .init())
  }

}

final class VergeNormalizationDerivedTests: XCTestCase {

  func test_subscribe() {

    let exp = expectation(description: "wait")

    let store = Store<DemoState, Never>(
      initialState: .init()
    )

    let derived = store
      .normalizedStorage(.keyPath(\.db))
      .table(.keyPath(\.book))
      .derived(from: Book.TypedID.init("1"))

    let received: OSAllocatedUnfairLock<[Book?]> = .init(initialState: [])

    derived.sinkState { value in
      received.withLock {
        $0.append(value.primitive.wrapped)
      }
      if value.primitive.wrapped != nil {
        exp.fulfill()
      }
    }
    .storeWhileSourceActive()

    _ = store.commit {
      $0.db.performBatchUpdates { t in
        t.modifying.book.insert(.init(rawID: "1", authorID: .init("muukii")))
      }
    }

    wait(for: [exp])

    XCTAssertEqual(received.withLock { $0 }, [nil, .init(rawID: "1", authorID: .init("muukii"))])

    withExtendedLifetime(derived, {})
  }

}
