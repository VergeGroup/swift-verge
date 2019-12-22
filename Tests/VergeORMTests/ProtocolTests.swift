//
//  ProtocolTests.swift
//  VergeORMTests
//
//  Created by muukii on 2019/12/22.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeORM

protocol Partial {
  var author: Author.EntityTableKey { get }
}

struct Database: DatabaseType {
  
  struct Schema: EntitySchemaType, Partial {
    let book = Book.EntityTableKey()
    let author = Author.EntityTableKey()
  }
  
  struct Indexes: IndexesType {
  }
    
  var _backingStorage: BackingStorage = .init()
}

class ProtocolTests: XCTest {
  
  func testPartialAccess() {
    
    var db = Database()
    db.performBatchUpdates { (c) -> Void in
      c.author.insertsOrUpdates.insert(Author(rawID: "author.0"))
    }
    
    func access<DB: DatabaseType>(db: DB) -> Int where DB.Schema : Partial {
      db.entities.author.all().count
    }
    
    XCTAssertEqual(access(db: db), 1)
    
  }
}
