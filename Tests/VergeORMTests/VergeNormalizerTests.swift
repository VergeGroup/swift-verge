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
       
    struct MappingTable: MappingTableType {
      let book = MappingKey<Book>()
      let author = MappingKey<Author>()
    }
    
    var backingStorage: BackingStorage<RootState.Entity.MappingTable> = .init()
   
  }
  
  var entity = Entity()
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
    
    state.entity.performBatchUpdate { (context) in
      
      let book = Book(rawID: "some")
      context.insertsOrUpdates.book.insert(book)
    }
    
    XCTAssertEqual(state.entity.book.count, 1)
    
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}
