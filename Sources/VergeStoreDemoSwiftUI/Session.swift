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
  
  private(set) lazy var users = self.store.makeMemoizeGetter(
  equality: .init(selector: { $0.db.entities.user }),
  selector: { state in
  state.db.entities.user.find(in: state.db.orderTables.userIDs)
  })
  
  init() {
    
  }
    
}

enum Entity {
  struct Post: EntityType, Equatable {
    let rawID: String
    var title: String
    var userID: User.ID
    var commentIDs: [Comment.ID] = []
  }
  
  struct User: EntityType, Equatable {
    let rawID: String
    var name: String
  }
  
  struct Comment: EntityType, Equatable {
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
    
    struct OrderTables: OrderTablesType {
      let userIDs = Entity.User.OrderTableKey(name: "userIDs")
      let postIDs = Entity.Post.OrderTableKey(name: "postIDs")
    }
       
    var storage: DatabaseStorage<SessionState.Database.Schema, SessionState.Database.OrderTables> = .init()
  }
    
  var db: Database = .init()
  
  var postIDsByUser: [Entity.User.ID : [Entity.Post.ID]] = [:]
}

final class SessionStore: StoreBase<SessionState> {
      
  init() {
    super.init(initialState: .init(), logger: DefaultLogger.shared)
  }
}

final class SessionDispatcher: DispatcherBase<SessionState> {
  
  func insertSampleUsers() -> Mutation {
    return .mutation { s in
      s.db.performBatchUpdate { (context) in
        let paul = Entity.User(rawID: "paul", name: "Paul Gilbert")
        let billy = Entity.User(rawID: "billy", name: "Billy Sheehan")
        let pat = Entity.User(rawID: "pat", name: "Pat Torpey")
        let eric = Entity.User(rawID: "eric", name: "Eric Martin")
        
        let ids = context.insertsOrUpdates.user.insert([
          paul,
          billy,
          pat,
          eric
        ])

        context.orderTables.userIDs.removeAll()
        context.orderTables.userIDs.append(contentsOf: ids)
        
      }
    }
  }
  
  func submitNewPost(title: String, from user: Entity.User) -> Mutation {
    return .mutation { (s) in
      let post = Entity.Post(rawID: UUID().uuidString, title: title, userID: user.id)
      s.db.performBatchUpdate { (context) in
        let id = context.insertsOrUpdates.post.insert(post)
        context.orderTables.postIDs.append(id)
        
        if let _ = s.postIDsByUser[user.id] {
          s.postIDsByUser[user.id]!.append(id)
        } else {
          s.postIDsByUser[user.id] = [id]
        }
      }
    }
  }
}

