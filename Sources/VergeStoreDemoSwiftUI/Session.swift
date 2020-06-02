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

final class Session: Equatable {
  
  static func == (lhs: Session, rhs: Session) -> Bool {
    lhs === rhs
  }

  let store = SessionStore()
  
  private(set) lazy var sessionDispatcher = SessionDispatcher(targetStore: store)

  private(set) lazy var users = store.derived(
    .map(
      derive: { ($0.db.entities.user, $0.db.indexes.userIDs) },
      dropsDerived: ==,
      compute: { (userTable, index) in
        userTable.find(in: index)
    })
  )

  init() {

    sessionDispatcher.insertSampleUsers()
    sessionDispatcher.insertSamplePosts()
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

final class SessionStore: Store<SessionState, Never> {
      
  init() {
    super.init(initialState: .init(), logger: DefaultStoreLogger.shared)
  }
}

let queue = DispatchQueue.global(qos: .default)

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
    queue.async {
      self.commit { (s) in
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

  func insertSamplePosts() {
    queue.async {
      self.commit {
        $0.db.performBatchUpdates { context in
          let posts = (0..<10000).map { i in Entity.Post(rawID: UUID().uuidString, title: "\(i)", userID: .init("paul")) }
          let results = context.post.insert(posts)
          context.indexes.postIDs.append(contentsOf: results.map { $0.entityID })
        }
      }
    }

  }
}

