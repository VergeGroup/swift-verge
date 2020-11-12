//
//  MiddlewareTests.swift
//  VergeORMTests
//
//  Created by muukii on 2019/12/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeORM

class MiddlewareTests: XCTestCase {
  
  var state = RootState()
  
  func testAutomaticIndex() {
    state.db.performBatchUpdates { (context) in
      
      let author = Author(rawID: "author.1")
      context.entities.author.insert(author)
    }
    
    XCTAssertEqual(state.db.indexes.bookMiddleware.count, 1)
  }
}
