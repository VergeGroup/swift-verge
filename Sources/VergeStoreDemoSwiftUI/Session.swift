//
//  Session.swift
//  VergeStoreDemoSwiftUI
//
//  Created by muukii on 2019/12/08.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import Combine

import VergeCore
import VergeStore
import VergeORM

final class Session: ObservableObject {
  
  var objectWillChange: ObservableObjectPublisher {
    store.objectWillChange
  }
  
  let store = SessionStore()
  private(set) lazy var sessionDispatcher = SessionDispatcher(target: store)
  
  private(set) lazy var users = self.store.makeGetter {
    $0.changed(keySelector: \.db.entities.user, comparer: .init(==))
      .map { state in
        state.db.entities.user.find(in: state.db.indexes.userIDs)
    }
  }
  
  init() {
    
  }
  
}

enum Entity {
  struct Post: EntityType, Identifiable, Equatable {
    
    typealias EntityIDRawType = String
    var entityID: EntityID {
      .init(rawID)
    }
    let rawID: String
    var title: String
    var userID: User.EntityID
    var commentIDs: [Comment.EntityID] = []
  }
  
  struct User: EntityType, Identifiable, Equatable {
    typealias EntityIDRawType = String
    var entityID: EntityID {
      .init(rawID)
    }
    let rawID: String
    var name: String
  }
  
  struct Comment: EntityType, Identifiable, Equatable {
    typealias EntityIDRawType = String
    var entityID: EntityID {
      .init(rawID)
    }
    let rawID: String
    var text: String
    var postID: Post.EntityID
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
      let postIDsAuthorGrouped = IndexKey<GroupByEntityIndex<Schema, Entity.User, Entity.Post>>()
    }
       
    var _backingStorage: BackingStorage = .init()
  }
    
  var db: Database = .init()

}

final class SessionStore: StoreBase<SessionState, Never> {
      
  init() {
    super.init(initialState: .init(), logger: DefaultStoreLogger.shared)
  }
}

final class SessionDispatcher: SessionStore.Dispatcher {
  
  func insertSampleUsers() {
    commit { s in
      s.db.performBatchUpdates { (context) in
        let paul = Entity.User(rawID: "paul", name: "Paul Gilbert")
        let billy = Entity.User(rawID: "billy", name: "Billy Sheehan")
        let pat = Entity.User(rawID: "pat", name: "Pat Torpey")
        let eric = Entity.User(rawID: "eric", name: "Eric Martin")
        
        let results = context.user.insert([
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
  
  func submitNewPost(title: String, from user: Entity.User) {
    dispatch { c in
      c.commit { (s) in
        let post = Entity.Post(rawID: UUID().uuidString, title: title, userID: user.entityID)
        s.db.performBatchUpdates { (context) in
          
          let postID = context.post.insert(post).entityID
          context.indexes.postIDs.append(postID)
          
          context.indexes.postIDsAuthorGrouped.update(in: user.entityID) { (index) in
            index.append(postID)
          }
        }
      }
    }
  }
}

