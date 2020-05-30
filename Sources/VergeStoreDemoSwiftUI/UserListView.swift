//
//  UserListView.swift
//  VergeStoreDemoSwiftUI
//
//  Created by muukii on 2019/12/08.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import SwiftUI
import VergeStore
import VergeCore

struct UserListView: View {
  
  var session: Session

  private var users: Derived<[Entity.User]> {
    session.users
  }
           
  var body: some View {
    
    NavigationView {
      UseState(users) { state in
        List {
          ForEach(state.value.root) { user in
            NavigationLink(destination: SubmitView(session: self.session, user: user)) {
              Text(user.name)
            }
          }
        }
      }
      .navigationBarTitle("Users")
    }
    .onAppear {
      self.session.sessionDispatcher.insertSampleUsers()
    }
  }
}

struct SubmitView: View, Equatable {
  
  var session: Session
  
  let samples = [
    "cart",
    "manager",
    "illness",
    "agony",
    "ghostwriter",
    "lecture",
    "great",
    "exact",
    "ticket",
    "disappointment",
  ]
  
  let user: Entity.User
  
  private var posts: [Entity.Post] {
    
    session.store.primitiveState.db.entities.post.find(in:
      session.store.primitiveState.db.indexes.postIDsAuthorGrouped.orderedID(in: user.entityID)
    )
  }
  
  var body: some View {
    UseState(session.store) { (store) in
      VStack {
        Button(action: {
          self.session.sessionDispatcher.submitNewPost(title: self.samples.randomElement()!, from: self.user)
        }) {
          Text("Submit")
        }
        List {
          ForEach(self.posts) { post in
            PostView(session: self.session, post: post)
          }
        }
      }
    }
  }
}

struct AllPostsView: View, Equatable {
  
  var session: Session
  
  private var posts: [Entity.Post] {
    session.store.primitiveState.db.entities.post.find(in: session.store.primitiveState.db.indexes.postIDs)
  }
    
  var body: some View {
    UseState(session.store) { _ in
      NavigationView {
        List {
          ForEach(self.posts) { post in
            PostView(session: self.session, post: post)
          }
        }
        .navigationBarTitle("Posts")
      }
    }
  }
  
}

struct PostView: View {
  
  var session: Session
  
  let post: Entity.Post
  
  private var user: Entity.User? {
    session.store.primitiveState.db.entities.user.find(by: post.userID)
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      Text(post.title)
      if user != nil {
        Text(user!.name)
      }
    }
  }
}


