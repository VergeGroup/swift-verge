//
//  VergeNormalizerTests.swift
//  VergeNormalizerTests
//
//  Created by muukii on 2019/12/07.
//  Copyright © 2019 muukii. All rights reserved.
//

import XCTest

import VergeORM

struct Book: EntityType {
  
  let rawID: String
  
}

struct Author: EntityType {
  
  let rawID: String
}

struct RootState {
  
  struct Entity: DatabaseType {
              
    struct Schema: EntitySchemaType {
      let book = MappingKey<Book>()
      let author = MappingKey<Author>()
    }
    
    struct OrderTables: OrderTablesType {
      let bookA = OrderTablePropertyKey<Book>(name: "bookA")
    }
    
    var entityBackingStorage: BackingEntityStorage<RootState.Entity.Schema, Read> = .init()
    var orderTableBackingStorage: BackingOrderTableStorage<RootState.Entity.OrderTables, Read> = .init()
   
  }
  
  var db = Entity()
}

class VergeNormalizerTests: XCTestCase {
  
  override func setUp() {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
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
    
    state.db.performBatchUpdate { (context) in
      context.deletes.book.insert(Book.ID.init(raw: "some"))
    }
    
    XCTAssertEqual(state.db.entities.book.count, 0)
    XCTAssertEqual(state.db.orderTables.bookA.count, 0)
    
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}
