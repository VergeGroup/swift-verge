
import Foundation

import XCTest

import Verge
import VergeORM

#if canImport(Combine)
import Combine
#endif

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
final class DerivedTests: XCTestCase {

  private var subscriptions = Set<AnyCancellable>()
  
  func testSelector() {
    
    let store = Store<RootState, Never>.init(initialState: .init(), logger: nil)
    
    let id = Book.EntityID.init("some")
    
    let nullableDerived = store.databases.db.derived(from: id, queue: .passthrough)
    
    XCTAssertNil(nullableDerived.state.primitive.wrapped, "It should be nil because the target entity is not stored.")
    
    XCTContext.runActivity(named: "simple") { (a) -> Void in
      let waiter = XCTWaiter()
      
      let didUpdate = XCTestExpectation()
      
      nullableDerived.statePublisher()
        .dropFirst(1).sink { _ in
          didUpdate.fulfill()
      }
      .store(in: &subscriptions)
            
      var book: Book!
      
      store.commit { state in
        let createdBook = state.db.performBatchUpdates { (context) -> Book in
          
          let book = Book(rawID: id.raw, authorID: Author.anonymous.entityID)
          context.entities.book.insert(book)
          context.indexes.allBooks.append(book.entityID)
          
          return book
        }
        
        book = createdBook
      }
      
      let nonnullDerived = store.databases.db.derivedNonNull(
        from: book
      )
      
      XCTAssertNotNil(nullableDerived.state.primitive.wrapped)
      XCTAssertNotNil(nonnullDerived.state.primitive.wrapped)
      
      XCTAssertNotNil(nullableDerived.state.wrapped?.name, "initial")
      XCTAssertEqual(nonnullDerived.state.wrapped.name, "initial")
      
      waiter.wait(for: [didUpdate], timeout: 2)
      
      XCTContext.runActivity(named: "modify") { (_) -> Void in
        
        store.commit { state in
          state.db.performBatchUpdates { (context) -> Void in
            
            var book = context.entities.book.current.find(by: id)!
            book.name = "Hey"
            context.entities.book.insert(book)
            
          }
        }
                
        XCTAssertEqual(nullableDerived.state.primitive.wrapped!.name, "Hey")
        XCTAssertEqual(nonnullDerived.state.primitive.name, "Hey")
        
      }
      
      XCTContext.runActivity(named: "delete") { (_) -> Void in
        
        store.commit { state in
          state.db.performBatchUpdates { (context) -> Void in
            
            context.entities.book.delete(id)
            
          }
        }
        
        XCTAssertEqual(nonnullDerived.state.primitive.name, "Hey")
        XCTAssertEqual(nullableDerived.state.primitive.wrapped == nil, true)
        
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
            
      let selector = storage.databases.db.derivedNonNull(from: result)
      
      XCTAssertEqual(selector.state.primitive.rawID, "some")
      XCTAssertEqual(selector.state.primitive.name, "initial")
      
      XCTContext.runActivity(named: "modify") { (_) -> Void in
        
        storage.commit { state in
          state.db.performBatchUpdates { (context) -> Void in
            
            var book = context.entities.book.current.find(by: .init("some"))!
            book.name = "Hey"
            context.entities.book.insert(book)
            
          }
        }
        
        XCTAssertEqual(selector.state.primitive.name, "Hey")
        
      }
      
      XCTContext.runActivity(named: "delete") { (_) -> Void in
        
        storage.commit { state in
          state.db.performBatchUpdates { (context) -> Void in
            
            context.entities.book.delete(.init("some"))
            
          }
        }
        
        XCTAssertEqual(selector.state.primitive.name, "Hey")
        
      }
    }
    
  }
  
  func testEqualsWithEquatableEntity() {
    
    let storage = Store<RootState, Never>.init(initialState: .init(), logger: nil)
    
    let result = storage.commit { state in
      state.db.performBatchUpdates { (context) -> EntityTable<RootState.Database.Schema, Author>.InsertionResult in
        
        let author = Author(rawID: "muukii", name: "muukii")
        let r = context.entities.author.insert(author)
        return r
      }
    }
    
    var targetAuthorUpdatedCount = 0

    let authorGetter = storage.databases.db.derivedNonNull(from: result)
    
    authorGetter.statePublisher()
      .dropFirst(1).sink { _ in
      targetAuthorUpdatedCount += 1
    }
    .store(in: &subscriptions)
    
    XCTAssertEqual(authorGetter.state.primitive.name, "muukii")
    
    XCTContext.runActivity(named: "updateName") { _ in
      
      _ = storage.commit { state in
        state.db.performBatchUpdates { (context) in
          context.entities.author.updateIfExists(id: .init("muukii")) { (author) in
            author.name = "Hiroshi"
          }
        }
      }
      
      XCTAssertEqual(authorGetter.state.primitive.name, "Hiroshi")
      
    }
    
    XCTAssertEqual(targetAuthorUpdatedCount, 1)
    
    XCTContext.runActivity(named: "updateName, but same value") { _ in

      _ = storage.commit { state in
        state.db.performBatchUpdates { (context) in
          context.entities.author.updateIfExists(id: .init("muukii")) { (author) in
            author.name = "Hiroshi"
          }
        }
      }
      
      XCTAssertEqual(authorGetter.state.primitive.name, "Hiroshi")
      
    }

    // no update
    XCTAssertEqual(targetAuthorUpdatedCount, 1)

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
    
    XCTAssertEqual(targetAuthorUpdatedCount, 1)

  }
  
  func testPerformanceGetterCreationIncludesFirstTime() {
    
    let storage = Store<RootState, Never>.init(initialState: .init(), logger: nil)
    
    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      let _ = storage.databases.db.derived(from: Author.EntityID("Hoo"), queue: .passthrough)
    }
    
  }
  
  func testPerformanceGetterCreationWithCache() {
    
    let storage = Store<RootState, Never>.init(initialState: .init(), logger: nil)
    
    let _ = storage.databases.db.derived(from: Author.EntityID("Hoo"), queue: .passthrough)
    
    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      let _ = storage.databases.db.derived(from: Author.EntityID("Hoo"), queue: .passthrough)
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
        _ = store.databases.db.derived(from: Author.EntityID("\(i)"))
      }
    }

  }
}
