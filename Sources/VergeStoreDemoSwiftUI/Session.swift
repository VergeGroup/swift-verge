//
//  Session.swift
//  VergeStoreDemoSwiftUI
//
//  Created by muukii on 2019/12/08.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import Combine

import VergeStore
import VergeORM

final class Session: ObservableObject {
  
  var objectWillChange: ObservableObjectPublisher {
    store.objectWillChange
  }
  
  let store = SessionStore()
  private(set) lazy var sessionDispatcher = SessionDispatcher(target: store)
  
  private(set) lazy var users = self.store.selector(
    selector: { state in
      state.db.entities.user.find(in: state.db.indexes.userIDs)
  },
    equality: .init(selector: { $0.db.entities.user })
  )
  
  init() {
    
  }
  
}

enum Entity {
  struct Post: EntityType, Identifiable, Equatable {
    typealias IdentifierType = String
    var id: ID {
      ID(rawID)
    }
    let rawID: String
    var title: String
    var userID: User.ID
    var commentIDs: [Comment.ID] = []
  }
  
  struct User: EntityType, Identifiable, Equatable {
    typealias IdentifierType = String
    var id: ID {
      ID(rawID)
    }
    let rawID: String
    var name: String
  }
  
  struct Comment: EntityType, Identifiable, Equatable {
    typealias IdentifierType = String
    var id: ID {
      ID(rawID)
    }
    let rawID: String
    var text: String
    var postID: Post.ID
  }
}

struct SessionState: StateType {
  
  struct Database: DatabaseType {
    
    struct Schema: EntitySchemaType {
      
      let post = Entity.Post.EntityTableKey()
      let user = Entity.User.EntityTableKey()
      let comment = Entity.Comment.EntityTableKey()
    }
    
    struct Indexes: IndexesType {
      let userIDs = IndexKey<OrderedIDIndex<Schema, Entity.User>>()
      let postIDs = IndexKey<OrderedIDIndex<Schema, Entity.Post>>()
      let postIDsAuthorGrouped = IndexKey<GroupByIndex<Schema, Entity.User, Entity.Post>>()
    }
       
    var _backingStorage: BackingStorage = .init()
  }
    
  var db: Database = .init()

}

final class SessionStore: StoreBase<SessionState, Never> {
      
  init() {
    super.init(initialState: .init(), logger: DefaultLogger.shared)
  }
}

final class SessionDispatcher: SessionStore.Dispatcher {
  
  func insertSampleUsers() -> Mutation<Void> {
    return .mutation { s in
      s.db.performBatchUpdates { (context) in
        let paul = Entity.User(rawID: "paul", name: "Paul Gilbert")
        let billy = Entity.User(rawID: "billy", name: "Billy Sheehan")
        let pat = Entity.User(rawID: "pat", name: "Pat Torpey")
        let eric = Entity.User(rawID: "eric", name: "Eric Martin")
        
        let results = context.user.insertsOrUpdates.insert([
          paul,
          billy,
          pat,
          eric
        ])
        
        context.indexes.userIDs.removeAll()
        context.indexes.userIDs.append(contentsOf: results.map { $0.entityID })
        
      }      
    }
  }
  
  func submitNewPost(title: String, from user: Entity.User) -> Mutation<Void> {
    return .mutation { (s) in
      let post = Entity.Post(rawID: UUID().uuidString, title: title, userID: user.id)
      s.db.performBatchUpdates { (context) in
        
        let postID = context.post.insertsOrUpdates.insert(post).entityID
        context.indexes.postIDs.append(postID)
        
        context.indexes.postIDsAuthorGrouped.update(in: user.id) { (index) in
          index.append(postID)
        }
      }
    }
  }
}

