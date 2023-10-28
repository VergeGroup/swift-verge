//
//  State.swift
//  VergeORMTests
//
//  Created by muukii on 2019/12/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import Verge
import VergeORM
import VergeMacros

struct Book: EntityType, Hashable {
  
  typealias EntityIDRawType = String
  
  var entityID: EntityID {
    .init(rawID)
  }
  
  let rawID: String
  let authorID: Author.EntityID
  var name: String = "initial"
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

struct RootState: StateType {
  static func reduce(modifying: inout RootState, current: Verge.Changes<RootState>, transaction: inout Verge.Transaction) {
  }

  @DatabaseState
  struct Database {
          
    struct Schema: EntitySchemaType {
      let book = Book.EntityTableKey()
      let author = Author.EntityTableKey()
    }
    
    struct Indexes: IndexesType {
      let allBooks = OrderedIDIndex<Schema, Book>.Key()
      let allAuthros = OrderedIDIndex<Schema, Author>.Key()
      let authorGroupedBook = GroupByEntityIndex<Schema, Author, Book>.Key()
      let bookMiddleware = OrderedIDIndex<Schema, Author>.Key()
    }
    
    var middlewares: [AnyMiddleware<RootState.Database>] {
      [
        AnyMiddleware<RootState.Database>(performAfterUpdates: { (context) in
          let ids = context.entities.author.all().map { $0.entityID }
          context.indexes.bookMiddleware.append(contentsOf: ids)
        })
      ]
    }
  }
  
  struct Other: Equatable {
    var count: Int = 0
    var collection: [Int] = []
    @Edge var dictionary: [AnyHashable : Any] = [:]

    mutating func makeAsHuge() {
      collection = Array.init(repeating: 5, count: 50000)
      for _ in 0..<50000 {
        dictionary[UUID()] = 500
      }
    }
  }
  
  var db = Database()
  var other = Other()
}
