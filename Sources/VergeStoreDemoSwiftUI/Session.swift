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
  
  init() {
    
  }
    
}

enum Entity {
  struct Post: EntityType {
    let rawID: String
    var title: String
    var userID: User.ID
    var commentIDs: [Comment.ID] = []
  }
  
  struct User: EntityType {
    let rawID: String
    var name: String
  }
  
  struct Comment: EntityType {
    let rawID: String
    var text: String
    var postID: Post.ID
  }
}

struct SessionState: StateType {
  
  struct Database: DatabaseType {
    
    static func makeEmtpy() -> SessionState.Database {
      .init()
    }
    
    var post = Entity.Post.makeTable()
    var user = Entity.User.makeTable()
    var comment = Entity.Comment.makeTable()
    
    mutating func merge(database: SessionState.Database) {
      mergeTable(keyPath: \.post, otherDatabase: database)
      mergeTable(keyPath: \.user, otherDatabase: database)
      mergeTable(keyPath: \.comment, otherDatabase: database)
    }
    
  }
    
  var entity: Database = .init()
  
  var userIDs: [Entity.User.ID] = []
  var postIDs: [Entity.Post.ID] = []
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
      s.entity.performBatchUpdate { (context) in
        let paul = Entity.User(rawID: "paul", name: "Paul Gilbert")
        let billy = Entity.User(rawID: "billy", name: "Billy Sheehan")
        let pat = Entity.User(rawID: "pat", name: "Pat Torpey")
        let eric = Entity.User(rawID: "eric", name: "Eric Martin")
        
        s.userIDs = context.insertOrUpdates.user.insert([
          paul,
          billy,
          pat,
          eric
        ])
        
      }
    }
  }
  
  func submitNewPost(title: String, from user: Entity.User) -> Mutation {
    return .mutation { (s) in
      let post = Entity.Post(rawID: UUID().uuidString, title: title, userID: user.id)
      s.entity.performBatchUpdate { (context) in
        let id = context.insertOrUpdates.post.insert(post)
        s.postIDs.append(id)
        
        if let _ = s.postIDsByUser[user.id] {
          s.postIDsByUser[user.id]!.append(id)
        } else {
          s.postIDsByUser[user.id] = [id]
        }
      }
    }
  }
}

