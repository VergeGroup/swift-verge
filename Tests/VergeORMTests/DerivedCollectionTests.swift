
import Foundation

import XCTest

import VergeStore
import VergeORM

#if canImport(Combine)
import Combine
#endif

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
class DerivedCollectionTests: XCTestCase {
  
  private var subscriptions = Set<AnyCancellable>()

  func testBasic() {

    let store = Store<RootState, Never>.init(initialState: .init(), logger: nil)

    store.commit {
      $0.db.performBatchUpdates { context in
        let authors = (0..<10).map { i in
          Author(rawID: "\(i)")
        }
        let result = context.author.insert(authors)
        context.indexes.allAuthros.append(contentsOf: result.map(\.entityID))
      }
    }
    
    let d = store.derivedQueriedEntities(update: { index -> AnyCollection<Author.EntityID> in
      return AnyCollection(index.allAuthros.prefix(3))
    })

    // FIXME: this fails, since the middleware doesn't care the order
    XCTAssertEqual(d.value.map { $0.value.entityID?.raw }, ["0", "1", "2"])

  }

  func testOutsideChange() {

    let store = Store<RootState, Never>.init(initialState: .init(), logger: nil)

    store.commit {
      $0.db.performBatchUpdates { context in
        let authors = (0..<10).map { i in
          Author(rawID: "\(i)")
        }
        let result = context.author.insert(authors)
        context.indexes.allAuthros.append(contentsOf: result.map(\.entityID))
      }
    }

    let d = store.derivedQueriedEntities(update: { index -> AnyCollection<Author.EntityID> in
      return AnyCollection(index.allAuthros.filter { $0.raw.first == "1" })
    })

    XCTAssertEqual(d.value.map { $0.value.entityID?.raw }, ["1"])

    store.commit {
      $0.db.performBatchUpdates { context in
        context.author.deleteAll()
        context.indexes.allAuthros.removeAll()

        let author = Author(rawID: "\(10)")
        let result = context.author.insert(author)
        context.indexes.allAuthros.append(result.entityID)
      }
    }

    XCTAssertEqual(d.value.map { $0.value.entityID?.raw }, ["10"])
  }

  func testInsideChange() {
    let store = Store<RootState, Never>.init(initialState: .init(), logger: nil)

    store.commit {
      $0.db.performBatchUpdates { context in
        let authors = (0..<10).map { i in
          Author(rawID: "\(i)")
        }
        let result = context.author.insert(authors)
        context.indexes.allAuthros.append(contentsOf: result.map(\.entityID))
      }
    }

    let d = store.derivedQueriedEntities(update: { index -> AnyCollection<Author.EntityID> in
      return AnyCollection(index.allAuthros.filter { $0.raw.first == "1" })
    })

    XCTAssertEqual(d.value.map { $0.value.entityID?.raw }, ["1"])

    let _ = store.commit {
      $0.db.performBatchUpdates { context in
        context.author.updateIfExists(id: .init("\(1)")) { author in
          author.name = "\(1)"
        }
      }
    }

    XCTAssertEqual(d.value.map { $0.value.entityID?.raw }, ["1"])
    XCTAssertEqual(d.value.map { $0.value.name }, ["1"])
  }
  
  
  func testInnerDerivedCache() {
    let store = Store<RootState, Never>.init(initialState: .init(), logger: nil)

    store.commit {
      $0.db.performBatchUpdates { context in
        let authors = (0..<10).map { i in
          Author(rawID: "\(i)")
        }
        let result = context.author.insert(authors)
        context.indexes.allAuthros.append(contentsOf: result.map(\.entityID))
      }
    }

    let d = store.derivedQueriedEntities(update: { index -> AnyCollection<Author.EntityID> in
      return AnyCollection(index.allAuthros.filter { _ in return true })
    })
    
    let tmp = d.value.primitive
    
    let _ = store.commit {
      $0.db.performBatchUpdates { context in
        context.indexes.allAuthros.removeAll()
        let authors = (0..<10).map { i in
          Author(rawID: "\(i)")
        }
        let result = context.author.insert(authors)
        context.indexes.allAuthros.append(contentsOf: result.map { $0.entityID} )
      }
    }
    
    for i in 0 ..< 10 {
       XCTAssert(d.value[AnyIndex(i)] === tmp[AnyIndex(i)])
    }
  }
  
  func testSinkStateCount() {
    
    let store = Store<RootState, Never>.init(initialState: .init(), logger: nil)
    var updateCount = 0

    let d = store.derivedQueriedEntities(update: { index -> AnyCollection<Author.EntityID> in
      return AnyCollection(index.allAuthros.filter { _ in return true })
    })

    d.sinkValue { _ in
      updateCount += 1
    }
    .store(in: &subscriptions)

    store.commit {
      $0.db.performBatchUpdates { context in
        let authors = (0..<10).map { i in
          Author(rawID: "\(i)")
        }
        let result = context.author.insert(authors)
        context.indexes.allAuthros.append(contentsOf: result.map(\.entityID))
      }
    }

    store.commit {
      $0.other.count += 1
    }
    
    XCTAssertEqual(updateCount, 2)
  }
}
