//
//  SelectorTests.swift
//  VergeORMTests
//
//  Created by muukii on 2019/12/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeCore
import VergeORM

class SelectorTests: XCTestCase {
  
  func testSelector() {
    
    let storage = Storage<RootState>(.init())
    
    let id = Book.EntityID.init("some")
    
    let nullableSelector = storage.entityGetter(
      from: id
    )
    
    XCTContext.runActivity(named: "simple") { (a) -> Void in
      let waiter = XCTWaiter()
      
      let didUpdate = XCTestExpectation()
      
      nullableSelector.addDidUpdate { (book) in
        didUpdate.fulfill()
      }
      
      XCTAssertNil(nullableSelector.value)
      
      var book: Book!
      
      storage.update { state in
        let createdBook = state.db.performBatchUpdates { (context) -> Book in
          
          let book = Book(rawID: id.raw, authorID: Author.anonymous.entityID)
          context.book.insertsOrUpdates.insert(book)
          context.indexes.allBooks.append(book.entityID)
          
          return book
        }
        
        book = createdBook
      }
      
      let selector = storage.nonNullEntityGetter(
        from: book
      )
      
      XCTAssertNotNil(nullableSelector.value)
      XCTAssertNotNil(selector.value)
      
      waiter.wait(for: [didUpdate], timeout: 2)
      
      XCTContext.runActivity(named: "modify") { (_) -> Void in
        
        storage.update { state in
          state.db.performBatchUpdates { (context) -> Void in
            
            var book = context.book.current.find(by: id)!
            book.name = "Hey"
            context.book.insertsOrUpdates.insert(book)
            
          }
        }
        
        XCTAssertEqual(selector.value.name, "Hey")
        XCTAssertEqual(nullableSelector.value!.name, "Hey")
        
      }
      
      XCTContext.runActivity(named: "delete") { (_) -> Void in
        
        storage.update { state in
          state.db.performBatchUpdates { (context) -> Void in
            
            context.book.deletes.insert(id)
            
          }
        }
        
        XCTAssertEqual(selector.value.name, "Hey")
        XCTAssertEqual(nullableSelector.value == nil, true)
        
      }
    }
    
  }
  
  func testSelectorUsingInsertionResult() {
    
    let storage = Storage<RootState>(.init())
        
    XCTContext.runActivity(named: "simple") { (a) -> Void in
                              
      let result = storage.update { state in
        state.db.performBatchUpdates { (context) -> EntityTable<RootState.Database.Schema, Book>.InsertionResult in
          
          let book = Book(rawID: "some", authorID: Author.anonymous.entityID)
          let r = context.book.insertsOrUpdates.insert(book)
          context.indexes.allBooks.append(book.entityID)
          
          return r
        }
      }
      
      let selector = storage.nonNullEntityGetter(from: result)
            
      XCTAssertEqual(selector.value.rawID, "some")
      XCTAssertEqual(selector.value.name, "")
            
      XCTContext.runActivity(named: "modify") { (_) -> Void in
        
        storage.update { state in
          state.db.performBatchUpdates { (context) -> Void in
            
            var book = context.book.current.find(by: .init("some"))!
            book.name = "Hey"
            context.book.insertsOrUpdates.insert(book)
            
          }
        }
        
        XCTAssertEqual(selector.value.name, "Hey")
        
      }
      
      XCTContext.runActivity(named: "delete") { (_) -> Void in
        
        storage.update { state in
          state.db.performBatchUpdates { (context) -> Void in
            
            context.book.deletes.insert(.init("some"))
            
          }
        }
        
        XCTAssertEqual(selector.value.name, "Hey")
        
      }
    }
    
  }
  
  func testEqualsWithNonEquatableEntity() {
    
    let storage = Storage<RootState>(.init())
    
    let result = storage.update { state in
      state.db.performBatchUpdates { (context) -> EntityTable<RootState.Database.Schema, Author>.InsertionResult in
        
        let author = Author(rawID: "muukii", name: "muukii")
        let r = context.author.insert(author)
        return r
      }
    }
    
    var updatedCount = 0
    
    let authorGetter = storage.nonNullEntityGetter(from: result)
    authorGetter.addDidUpdate { (_) in
      updatedCount += 1
    }
    
    XCTAssertEqual(authorGetter.value.name, "muukii")
    
    XCTContext.runActivity(named: "updateName") { _ in
      
      storage.update { state in
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
      
      storage.update { state in
        state.db.performBatchUpdates { (context) in
          context.author.updateIfExists(id: .init("muukii")) { (author) in
            author.name = "Hiroshi"
          }
        }
      }
      
      XCTAssertEqual(authorGetter.value.name, "Hiroshi")
      
    }
    
    XCTAssertEqual(updatedCount, 2)
        
    XCTContext.runActivity(named: "Update other") { _ in
      
      for _ in 0..<10 {
        
        storage.update { state in
          state.other.count += 1
        }
        
      }
      
    }
    
    XCTAssertEqual(updatedCount, 2)
    
  }
  
  func testGetterCache() {
    
    let storage = Storage<RootState>(.init())
    
    let getter1 = storage.entityGetter(from: Author.EntityID("Hoo"))
    let getter2 = storage.entityGetter(from: Author.EntityID("Hoo"))
    let getter3 = storage.entityGetter(from: Book.EntityID("Hoo"))
    
    XCTAssert(getter1 === getter2)
    XCTAssert(getter3 !== getter2)
    
  }
  
  func testPerformanceGetterCreationIncludesFirstTime() {
    
    let storage = Storage<RootState>(.init())
    
    measure {
      let _ = storage.entityGetter(from: Author.EntityID("Hoo"))
    }
    
  }
  
  func testPerformanceGetterCreationWithCache() {
        
    let storage = Storage<RootState>(.init())
    
    let _ = storage.entityGetter(from: Author.EntityID("Hoo"))
    
    measure {
      let _ = storage.entityGetter(from: Author.EntityID("Hoo"))
    }
                
  }
}
