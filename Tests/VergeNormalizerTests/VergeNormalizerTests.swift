//
//  VergeNormalizerTests.swift
//  VergeNormalizerTests
//
//  Created by muukii on 2019/12/07.
//  Copyright © 2019 muukii. All rights reserved.
//

import XCTest

import VergeNormalizer

struct Book: VergeTypedIdentifiable {
  
  let rawID: String
  
}

struct Author: VergeTypedIdentifiable {
  
  let rawID: String
}

struct RootState {
  
  struct Entity: VergeNormalizedDatabase {
    static func makeEmtpy() -> RootState.Entity {
      .init()
    }
    
    var book: Table<Book> = .init()
    var author: Table<Author> = .init()
            
    mutating func merge(database: RootState.Entity) {
      mergeTable(keyPath: \.book, otherDatabase: database)
      mergeTable(keyPath: \.author, otherDatabase: database)
    }
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
      context.update {
        $0.book.update(book)
      }
    }
    
    XCTAssertEqual(state.entity.book.entities.count, 1)
    
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}
