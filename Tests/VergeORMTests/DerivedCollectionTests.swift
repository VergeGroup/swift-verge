
import Foundation

import XCTest

import VergeStore
import VergeORM

#if canImport(Combine)
import Combine
#endif

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
class DerivedCollectionTests: XCTestCase {

  func testBasic() {

    let store = Store<RootState, Never>.init(initialState: .init(), logger: nil)

    store.commit {
      $0.db.performBatchUpdates { context in
        let authors = (0..<10).map { i in
          Author(rawID: "\(i)")
        }
        context.author.insert(authors)
      }
    }

    let d = store.derivedQueriedEntities(update: { index -> AnyCollection<Author.EntityID> in
      // FIXME: This line causes stack overflow without Array()
      return AnyCollection(Array(index.allAuthros).prefix(3))
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
        context.author.insert(authors)
      }
    }
    
    let d = store.derivedQueriedEntities(update: { index -> AnyCollection<Author.EntityID> in
      // FIXME: This line causes stack overflow without Array()
      return AnyCollection(Array(index.allAuthros).filter { $0.raw.first == "1" })
    })
    
    XCTAssertEqual(d.value.map { $0.value.entityID?.raw }, ["1"])
    
    store.commit {
      $0.db.performBatchUpdates { context in
        context.author.deleteAll()
        let author = Author(rawID: "\(10)")
        context.author.insert(author)
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
        context.author.insert(authors)
      }
    }
    
    let d = store.derivedQueriedEntities(update: { index -> AnyCollection<Author.EntityID> in
      // FIXME: This line causes stack overflow without Array()
      return AnyCollection(Array(index.allAuthros).filter { $0.raw.first == "1" })
    })
    
    XCTAssertEqual(d.value.map { $0.value.entityID?.raw }, ["1"])
    
    store.commit {
      $0.db.performBatchUpdates { context in
        context.author.updateIfExists(id: .init("\(1)")) { author in
          author.name = "\(1)"
        }
      }
    }
    
    XCTAssertEqual(d.value.map { $0.value.entityID?.raw }, ["10"])
  }
}
