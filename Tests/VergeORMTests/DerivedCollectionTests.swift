
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
        let result = context.author.insert(authors)
        context.indexes.allAuthros.append(contentsOf: result.map(\.entityID))
      }
    }

    let d = store.derivedQueriedEntities(update: { index -> AnyCollection<Author.EntityID> in
      return AnyCollection(index.allAuthros.prefix(3))
    })

    XCTAssertEqual(d.value.map { $0.entityID.raw }, ["0", "1", "2"])

  }
  
}
