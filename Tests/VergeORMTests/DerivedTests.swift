
import Foundation

import XCTest

import VergeStore
import VergeORM

#if canImport(Combine)
import Combine
#endif

@available(iOS 13, macOS 10.15, *)
class DerivedTests: XCTestCase {
  
  private var subscriptions = Set<AnyCancellable>()
  
  func testSelector() {
    
    let storage = Store<RootState, Never>.init(initialState: .init(), logger: nil)
    
    let id = Book.EntityID.init("some")
    
    let nullableSelector = storage.derived(from: id)
    
    XCTAssertNil(nullableSelector.value.wrapped)
    
    XCTContext.runActivity(named: "simple") { (a) -> Void in
      let waiter = XCTWaiter()
      
      let didUpdate = XCTestExpectation()
      
      nullableSelector.statePublisher
        .dropFirst(1).sink { _ in
          didUpdate.fulfill()
      }
      .store(in: &subscriptions)
            
      var book: Book!
      
      storage.commit { state in
        let createdBook = state.db.performBatchUpdates { (context) -> Book in
          
          let book = Book(rawID: id.raw, authorID: Author.anonymous.entityID)
          context.book.insert(book)
          context.indexes.allBooks.append(book.entityID)
          
          return book
        }
        
        book = createdBook
      }
      
      let selector = storage.derivedNonNull(
        from: book
      )
      
      XCTAssertNotNil(nullableSelector.value.wrapped)
      XCTAssertNotNil(selector.value.wrapped)
      
      waiter.wait(for: [didUpdate], timeout: 2)
      
      XCTContext.runActivity(named: "modify") { (_) -> Void in
        
        storage.commit { state in
          state.db.performBatchUpdates { (context) -> Void in
            
            var book = context.book.current.find(by: id)!
            book.name = "Hey"
            context.book.insert(book)
            
          }
        }
                
        XCTAssertEqual(selector.value.name, "Hey")
        XCTAssertEqual(nullableSelector.value.name!, "Hey")
        
      }
      
      XCTContext.runActivity(named: "delete") { (_) -> Void in
        
        storage.commit { state in
          state.db.performBatchUpdates { (context) -> Void in
            
            context.book.deletes.insert(id)
            
          }
        }
        
        XCTAssertEqual(selector.value.name, "Hey")
        XCTAssertEqual(nullableSelector.value.wrapped == nil, true)
        
      }
    }
    
  }
  
  func testSelectorUsingInsertionResult() {
    
    let storage = Store<RootState, Never>.init(initialState: .init(), logger: nil)
    
    XCTContext.runActivity(named: "simple") { (a) -> Void in
      
      let result = storage.commit { state in
        state.db.performBatchUpdates { (context) -> EntityTable<RootState.Database.Schema, Book>.InsertionResult in
          
          let book = Book(rawID: "some", authorID: Author.anonymous.entityID)
          let r = context.book.insert(book)
          context.indexes.allBooks.append(book.entityID)
          
          return r
        }
      }
      
      let selector = storage.nonNullEntityGetter(from: result)
      
      XCTAssertEqual(selector.value.rawID, "some")
      XCTAssertEqual(selector.value.name, "")
      
      XCTContext.runActivity(named: "modify") { (_) -> Void in
        
        storage.commit { state in
          state.db.performBatchUpdates { (context) -> Void in
            
            var book = context.book.current.find(by: .init("some"))!
            book.name = "Hey"
            context.book.insert(book)
            
          }
        }
        
        XCTAssertEqual(selector.value.name, "Hey")
        
      }
      
      XCTContext.runActivity(named: "delete") { (_) -> Void in
        
        storage.commit { state in
          state.db.performBatchUpdates { (context) -> Void in
            
            context.book.deletes.insert(.init("some"))
            
          }
        }
        
        XCTAssertEqual(selector.value.name, "Hey")
        
      }
    }
    
  }
  
  func testEqualsWithNonEquatableEntity() {
    
    let storage = Store<RootState, Never>.init(initialState: .init(), logger: nil)
    
    let result = storage.commit { state in
      state.db.performBatchUpdates { (context) -> EntityTable<RootState.Database.Schema, Author>.InsertionResult in
        
        let author = Author(rawID: "muukii", name: "muukii")
        let r = context.author.insert(author)
        return r
      }
    }
    
    var updatedCount = 0
    
    let authorGetter = storage.nonNullEntityGetter(from: result)
    
    authorGetter.dropFirst(1).sink { _ in
      updatedCount += 1
    }
    .store(in: &subscriptions)
    
    XCTAssertEqual(authorGetter.value.name, "muukii")
    
    XCTContext.runActivity(named: "updateName") { _ in
      
      _ = storage.commit { state in
        state.db.performBatchUpdates { (context) in
          context.author.updateIfExists(id: .init("muukii")) { (author) in
            author.name = "Hiroshi"
          }
        }
      }
      
      XCTAssertEqual(authorGetter.value.name, "Hiroshi")
      
    }
    
    XCTAssertEqual(updatedCount, 1)
    
    XCTContext.runActivity(named: "updateName, but not changed") { _ in
      
      _ = storage.commit { state in
        state.db.performBatchUpdates { (context) in
          context.author.updateIfExists(id: .init("muukii")) { (author) in
            author.name = "Hiroshi"
          }
        }
      }
      
      XCTAssertEqual(authorGetter.value.name, "Hiroshi")
      
    }
    
    XCTAssertEqual(updatedCount, 2)
    
    XCTContext.runActivity(named: "Update other, getter would not emit changes") { _ in
      
      for _ in 0..<10 {
        
        storage.commit { state in
          state.other.count += 1
        }
        
      }
      
    }
    
    XCTContext.runActivity(named: "Adding book, getter would not emit changes") { _ -> Void in
      
      _ = storage.commit { state in
        state.db.performBatchUpdates { (context) in
          context.book.insert(Book(rawID: "Verge", authorID: .init("muukii")))
        }
      }
      
      return
      
    }
    
    XCTContext.runActivity(named: "Add other author") { _ in
      
      _ = storage.commit { state in
        state.db.performBatchUpdates { (context) in
          context.author.insert(.init(rawID: "John", name: "John"))
        }
      }
      return
    }
    
    XCTAssertEqual(updatedCount, 2)
    
  }
  
  func testGetterCache() {
    
    let storage = Store<RootState, Never>.init(initialState: .init(), logger: nil)
    
    let getter1 = storage.entityGetter(from: Author.EntityID("Hoo"))
    let getter2 = storage.entityGetter(from: Author.EntityID("Hoo"))
    let getter3 = storage.entityGetter(from: Book.EntityID("Hoo"))
    
    XCTAssert(getter1 === getter2)
    XCTAssert(getter3 !== getter2)
    
  }
  
  func testPerformanceGetterCreationIncludesFirstTime() {
    
    let storage = Store<RootState, Never>.init(initialState: .init(), logger: nil)
    
    measure {
      let _ = storage.entityGetter(from: Author.EntityID("Hoo"))
    }
    
  }
  
  func testPerformanceGetterCreationWithCache() {
    
    let storage = Store<RootState, Never>.init(initialState: .init(), logger: nil)
    
    let _ = storage.entityGetter(from: Author.EntityID("Hoo"))
    
    measure {
      let _ = storage.entityGetter(from: Author.EntityID("Hoo"))
    }
    
  }
}
