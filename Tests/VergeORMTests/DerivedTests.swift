
import Foundation

import XCTest

import Verge
import VergeORM

#if canImport(Combine)
import Combine
#endif

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
class DerivedTests: XCTestCase {

  private var subscriptions = Set<AnyCancellable>()
  
  func testSelector() {
    
    let storage = Store<RootState, Never>.init(initialState: .init(), logger: nil)
    
    let id = Book.EntityID.init("some")
    
    let nullableSelector = storage.derived(from: id, queue: .passthrough)
    
    XCTAssertNil(nullableSelector.primitiveValue.wrapped)
    
    XCTContext.runActivity(named: "simple") { (a) -> Void in
      let waiter = XCTWaiter()
      
      let didUpdate = XCTestExpectation()
      
      nullableSelector.valuePublisher()
        .dropFirst(1).sink { _ in
          didUpdate.fulfill()
      }
      .store(in: &subscriptions)
            
      var book: Book!
      
      storage.commit { state in
        let createdBook = state.db.performBatchUpdates { (context) -> Book in
          
          let book = Book(rawID: id.raw, authorID: Author.anonymous.entityID)
          context.entities.book.insert(book)
          context.indexes.allBooks.append(book.entityID)
          
          return book
        }
        
        book = createdBook
      }
      
      let selector = storage.derivedNonNull(
        from: book,
        queue: .passthrough
      )
      
      XCTAssertNotNil(nullableSelector.primitiveValue.wrapped)
      XCTAssertNotNil(selector.primitiveValue.wrapped)
      
      waiter.wait(for: [didUpdate], timeout: 2)
      
      XCTContext.runActivity(named: "modify") { (_) -> Void in
        
        storage.commit { state in
          state.db.performBatchUpdates { (context) -> Void in
            
            var book = context.entities.book.current.find(by: id)!
            book.name = "Hey"
            context.entities.book.insert(book)
            
          }
        }
                
        XCTAssertEqual(selector.primitiveValue.name, "Hey")
        XCTAssertEqual(nullableSelector.primitiveValue.wrapped!.name, "Hey")
        
      }
      
      XCTContext.runActivity(named: "delete") { (_) -> Void in
        
        storage.commit { state in
          state.db.performBatchUpdates { (context) -> Void in
            
            context.entities.book.delete(id)
            
          }
        }
        
        XCTAssertEqual(selector.primitiveValue.name, "Hey")
        XCTAssertEqual(nullableSelector.primitiveValue.wrapped == nil, true)
        
      }
    }
    
  }
  
  func testSelectorUsingInsertionResult() {
    
    let storage = Store<RootState, Never>.init(initialState: .init(), logger: nil)
    
    XCTContext.runActivity(named: "simple") { (a) -> Void in
      
      let result = storage.commit { state in
        state.db.performBatchUpdates { (context) -> EntityTable<RootState.Database.Schema, Book>.InsertionResult in
          
          let book = Book(rawID: "some", authorID: Author.anonymous.entityID)
          let r = context.entities.book.insert(book)
          context.indexes.allBooks.append(book.entityID)
          
          return r
        }
      }
            
      let selector = storage.derivedNonNull(from: result, queue: .passthrough)
      
      XCTAssertEqual(selector.primitiveValue.rawID, "some")
      XCTAssertEqual(selector.primitiveValue.name, "")
      
      XCTContext.runActivity(named: "modify") { (_) -> Void in
        
        storage.commit { state in
          state.db.performBatchUpdates { (context) -> Void in
            
            var book = context.entities.book.current.find(by: .init("some"))!
            book.name = "Hey"
            context.entities.book.insert(book)
            
          }
        }
        
        XCTAssertEqual(selector.primitiveValue.name, "Hey")
        
      }
      
      XCTContext.runActivity(named: "delete") { (_) -> Void in
        
        storage.commit { state in
          state.db.performBatchUpdates { (context) -> Void in
            
            context.entities.book.delete(.init("some"))
            
          }
        }
        
        XCTAssertEqual(selector.primitiveValue.name, "Hey")
        
      }
    }
    
  }
  
  func testEqualsWithNonEquatableEntity() {
    
    let storage = Store<RootState, Never>.init(initialState: .init(), logger: nil)
    
    let result = storage.commit { state in
      state.db.performBatchUpdates { (context) -> EntityTable<RootState.Database.Schema, Author>.InsertionResult in
        
        let author = Author(rawID: "muukii", name: "muukii")
        let r = context.entities.author.insert(author)
        return r
      }
    }
    
    var updatedCount = 0
    
    let authorGetter = storage.derivedNonNull(from: result, queue: .passthrough)
    
    authorGetter.valuePublisher()
      .dropFirst(1).sink { _ in
      updatedCount += 1
    }
    .store(in: &subscriptions)
    
    XCTAssertEqual(authorGetter.primitiveValue.name, "muukii")
    
    XCTContext.runActivity(named: "updateName") { _ in
      
      _ = storage.commit { state in
        state.db.performBatchUpdates { (context) in
          context.entities.author.updateIfExists(id: .init("muukii")) { (author) in
            author.name = "Hiroshi"
          }
        }
      }
      
      XCTAssertEqual(authorGetter.primitiveValue.name, "Hiroshi")
      
    }
    
    XCTAssertEqual(updatedCount, 1)
    
    XCTContext.runActivity(named: "updateName, but not changed") { _ in
      
      _ = storage.commit { state in
        state.db.performBatchUpdates { (context) in
          context.entities.author.updateIfExists(id: .init("muukii")) { (author) in
            author.name = "Hiroshi"
          }
        }
      }
      
      XCTAssertEqual(authorGetter.primitiveValue.name, "Hiroshi")
      
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
          context.entities.book.insert(Book(rawID: "Verge", authorID: .init("muukii")))
        }
      }
      
      return
      
    }
    
    XCTContext.runActivity(named: "Add other author") { _ in
      
      _ = storage.commit { state in
        state.db.performBatchUpdates { (context) in
          context.entities.author.insert(.init(rawID: "John", name: "John"))
        }
      }
      return
    }
    
    XCTAssertEqual(updatedCount, 2)
    
  }
  
  func testPerformanceGetterCreationIncludesFirstTime() {
    
    let storage = Store<RootState, Never>.init(initialState: .init(), logger: nil)
    
    measure {
      let _ = storage.derived(from: Author.EntityID("Hoo"), queue: .passthrough)
    }
    
  }
  
  func testPerformanceGetterCreationWithCache() {
    
    let storage = Store<RootState, Never>.init(initialState: .init(), logger: nil)
    
    let _ = storage.derived(from: Author.EntityID("Hoo"), queue: .passthrough)
    
    measure {
      let _ = storage.derived(from: Author.EntityID("Hoo"), queue: .passthrough)
    }
    
  }

  func testPerformanceCreationDerivedFromBigState() {

    let store = Store<RootState, Never>.init(initialState: .init(), logger: nil)

    store.commit { state in
      state.db.performBatchUpdates { (context) in
        for i in 0..<10000 {
          context.entities.author.insert(.init(rawID: "\(i)", name: "John"))
        }
      }
    }

    store.commit {
      $0.other.makeAsHuge()
    }

    let option = XCTMeasureOptions()
    option.iterationCount = 10

    measure(metrics: [XCTClockMetric()], options: option) {
      for i in 0..<10000 {
        _ = store.derived(from: Author.EntityID("\(i)"))
      }
    }

  }
}
