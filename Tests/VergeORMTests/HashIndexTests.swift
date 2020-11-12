//
//  GroupByIndexTests.swift
//  VergeORMTests
//
//  Created by muukii on 2020/02/16.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeORM

class GroupByIndexTests: XCTestCase {
  
  struct RootState: DatabaseEmbedding {
    
    static let getterToDatabase: (RootState) -> RootState.Database = { $0.db }
    
    struct Database: DatabaseType {
      
      struct Schema: EntitySchemaType {
        let author = Author.EntityTableKey()
      }
      
      struct Indexes: IndexesType {
        let allBooks = HashIndex<Schema, String, Author>.Key()
      }
                  
      var _backingStorage: BackingStorage = .init()
    }
        
    var db = Database()
  }
  
  private let insertedStore: RootState = {
    
    var state = RootState()
    
    state.db.performBatchUpdates { (c) in
      
      for group in (0..<100).map({ $0.description }) {
        let authors = (0..<1000).map { i in
          Author(rawID: "author.\(i)")
        }
        c.entities.author.insert(authors)
      }
          
    }
    
    return state
  }()

  func testPerformance() {
    
  }
  
}
