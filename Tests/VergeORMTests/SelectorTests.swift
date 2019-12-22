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
    
    let id = Book.ID.init("some")
    
    let nullableSelector = storage.entitySelector(
      entityTableSelector: { $0.db.entities.book },
      entityID: id
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
          
          let book = Book(rawID: id.raw, authorID: Author.anonymous.id)
          context.book.insertsOrUpdates.insert(book)
          context.indexes.allBooks.append(book.id)
          
          return book
        }
        
        book = createdBook
      }
      
      let selector = storage.nonNullEntitySelector(
        entityTableSelector: { $0.db.entities.book },
        entity: book
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
          
          let book = Book(rawID: "some", authorID: Author.anonymous.id)
          let r = context.book.insertsOrUpdates.insert(book)
          context.indexes.allBooks.append(book.id)
          
          return r
        }
      }
      
      let selector = storage.nonNullEntitySelector(insertionResult: result)
            
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
}
