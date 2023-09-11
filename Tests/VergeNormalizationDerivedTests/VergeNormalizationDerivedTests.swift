import VergeNormalizationDerived
import XCTest

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
      .derivedEntity(entityID: Book.EntityID.init("1"))

    var received: [Book?] = []

    derived.sinkState { value in
      received.append(value.primitive.wrapped)
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

    XCTAssertEqual(received, [nil, .init(rawID: "1", authorID: .init("muukii"))])

    withExtendedLifetime(derived, {})
  }

  func test_cache() {

    let store = Store<DemoState, Never>(
      initialState: .init()
    )

    let derived1 = store
      .normalizedStorage(.keyPath(\.db))
      .table(.keyPath(\.book))
      .derivedEntity(entityID: Book.EntityID.init("1"))

    let derived2 = store
      .normalizedStorage(.keyPath(\.db))
      .table(.keyPath(\.book))
      .derivedEntity(entityID: Book.EntityID.init("1"))

    let derived3 = store
      .normalizedStorage(.keyPath(\.db))
      .table(.keyPath(\.book2))
      .derivedEntity(entityID: Book.EntityID.init("1"))

    XCTAssert(derived1 === derived2)
    XCTAssert(derived2 !== derived3)

  }

}
