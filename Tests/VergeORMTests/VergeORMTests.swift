//
//  VergeNormalizerTests.swift
//  VergeNormalizerTests
//
//  Created by muukii on 2019/12/07.
//  Copyright © 2019 muukii. All rights reserved.
//

import XCTest

import VergeCore
import VergeORM

struct Book: EntityType, Equatable {
  
  let rawID: String
  var name: String = ""
}

struct Author: EntityType {
  
  let rawID: String
}

struct RootState {
  
  struct Database: DatabaseType {
                  
    struct Schema: EntitySchemaType {
      let book = EntityTableKey<Book>()
      let author = EntityTableKey<Author>()
    }
    
    struct OrderTables: OrderTablesType {
      let bookA = OrderTableKey<Book>(name: "bookA")
    }
    
    var _backingStorage: BackingStorage = .init()
  }
  
  var db = Database()
}

class VergeNormalizerTests: XCTestCase {
  
  override func setUp() {
    // Put setup code here. This method is called before the invocation of each test method in the class.        
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func testEqualityEntityTable() {
    
    var state = RootState()
    
    state.db.performBatchUpdate { (context) in
      
      let book = Book(rawID: "some")
      context.insertsOrUpdates.book.insert(book)
    }
    
    let a = state.db.entities.book
    let b = state.db.entities.book
    
    XCTAssertEqual(a, b)
        
  }
  
  func testSimpleInsert() {
    
    var state = RootState()
    
    state.db.performBatchUpdate { (context) in
      
      let book = Book(rawID: "some")
      context.insertsOrUpdates.book.insert(book)
    }
    
    XCTAssertEqual(state.db.entities.book.count, 1)
    
  }
  
  func testManagingOrderTable() {
    
    var state = RootState()
    
    state.db.performBatchUpdate { (context) in
      
      let book = Book(rawID: "some")
      context.insertsOrUpdates.book.insert(book)
      context.orderTables.bookA.append(book.id)
    }
        
    XCTAssertEqual(state.db.entities.book.count, 1)
    XCTAssertEqual(state.db.orderTables.bookA.count, 1)
    
    print(state.db.orderTables.bookA)
    
    state.db.performBatchUpdate { (context) -> Void in
      context.deletes.book.insert(Book.ID.init(raw: "some"))
    }
    
    XCTAssertEqual(state.db.entities.book.count, 0)
    XCTAssertEqual(state.db.orderTables.bookA.count, 0)
    
  }
  
  func testUpdate() {
    
    var state = RootState()
    
    let id = Book.ID.init(raw: "some")
    
    state.db.performBatchUpdate { (context) in
      
      let book = Book(rawID: id.raw)
      context.insertsOrUpdates.book.insert(book)
    }
    
    XCTAssertNotNil(state.db.entities.book.find(by: id))
    
    state.db.performBatchUpdate { (context) in
      
      guard var book = context.current.entities.book.find(by: id) else {
        XCTFail()
        return
      }
      book.name = "hello"
      
      context.insertsOrUpdates.book.insert(book)
    }
    
    XCTAssertNotNil(state.db.entities.book.find(by: id))
    XCTAssertNotNil(state.db.entities.book.find(by: id)!.name == "hello")

  }
  
  func testSelector() {
    
    let storage = Storage<RootState>(.init())
    
    let id = Book.ID.init(raw: "some")
    
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
        let createdBook = state.db.performBatchUpdate { (context) -> Book in
          
          let book = Book(rawID: id.raw)
          context.insertsOrUpdates.book.insert(book)
          context.orderTables.bookA.append(book.id)
          
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
          state.db.performBatchUpdate { (context) -> Void in
            
            var book = context.current.entities.book.find(by: id)!
            book.name = "Hey"
            context.insertsOrUpdates.book.insert(book)
            
          }
        }
        
        XCTAssertEqual(selector.value.name, "Hey")
        XCTAssertEqual(nullableSelector.value!.name, "Hey")
        
      }
      
      XCTContext.runActivity(named: "delete") { (_) -> Void in
        
        storage.update { state in
          state.db.performBatchUpdate { (context) -> Void in
            
            context.deletes.book.insert(id)
            
          }
        }
        
        XCTAssertEqual(selector.value.name, "Hey")
        XCTAssertEqual(nullableSelector.value == nil, true)
        
      }
    }
      
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}
