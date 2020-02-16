//
//  SetIndexTests.swift
//  VergeORMTests
//
//  Created by muukii on 2020/02/16.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeORM

class SetIndexTests: XCTestCase {
  
  struct Database: DatabaseType {
    
    struct Schema: EntitySchemaType {
      let author = Author.EntityTableKey()
    }
    
    struct Indexes: IndexesType {
      let allBooks = SetIndex<Schema, Author>.Key()
    }
    
    var _backingStorage: BackingStorage = .init()
  }
  
  let db: Database = {
    var db = Database()
    db.performBatchUpdates { (c) in
      
      let authors = (0..<10000).map { i in
        Author(rawID: "author.\(i)")
      }
      c.author.insert(authors)
      c.indexes.allBooks.formUnion(authors.map { $0.entityID })
    }
    return db
  }()
    
  func testSample() {            
    measure {
      _ = db.indexes.allBooks.map { $0.raw }
    }
  }
  
  func testCompactMap() {
    measure {
      _ = db.indexes.allBooks.compactMap { $0.raw }
    }
  }
  
  func testFilter() {
    measure {
      _ = db.indexes.allBooks.sorted { $0.raw > $1.raw }
    }
  }
  
  
}
