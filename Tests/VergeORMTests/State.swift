//
//  State.swift
//  VergeORMTests
//
//  Created by muukii on 2019/12/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import VergeORM

struct Book: EntityType, Hashable {
  
  typealias EntityIDRawType = String
  
  var entityID: EntityID {
    .init(rawID)
  }
  
  let rawID: String
  let authorID: Author.EntityID
  var name: String = ""
}

struct Author: EntityType {
  
  typealias EntityIDRawType = String
  
  var entityID: EntityID {
    .init(rawID)
  }
    
  let rawID: String
  var name: String = ""
  
  static let anonymous: Author = .init(rawID: "anonymous")
}

struct RootState: DatabaseEmbedding {
  
  static let getterToDatabase: (RootState) -> RootState.Database = { $0.db }
  
  struct Database: DatabaseType {
          
    struct Schema: EntitySchemaType {
      let book = Book.EntityTableKey()
      let author = Author.EntityTableKey()
    }
    
    struct Indexes: IndexesType {
      let allBooks = OrderedIDIndex<Schema, Book>.Key()
      let authorGroupedBook = GroupByIndex<Schema, Author, Book>.Key()
      let bookMiddleware = OrderedIDIndex<Schema, Author>.Key()
    }
    
    var middlewares: [AnyMiddleware<RootState.Database>] {
      [
        AnyMiddleware<RootState.Database>(performAfterUpdates: { (context) in
          let ids = context.author.insertsOrUpdates.allIDs()
          context.indexes.bookMiddleware.append(contentsOf: ids)
        })
      ]
    }
    
    var _backingStorage: BackingStorage = .init()
  }
  
  struct Other {
    var count: Int = 0
  }
  
  var db = Database()
  var other = Other()
}
