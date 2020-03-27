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
  
  @EnvironmentObject var session: Session
  
  private var users: GetterSource<SessionState, [Entity.User]> {
    session.users
  }
           
  var body: some View {
    
    NavigationView {
      List {
        ForEach(users.value) { user in
          NavigationLink(destination: SubmitView(user: user)) {
            Text(user.name)
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

struct SubmitView: View {
  
  @EnvironmentObject var session: Session
  
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
    
    session.store.state.db.entities.post.find(in:
      session.store.state.db.indexes.postIDsAuthorGrouped.orderedID(in: user.entityID)
    )
  }
  
  var body: some View {
    VStack {
      Button(action: {
        self.session.sessionDispatcher.submitNewPost(title: self.samples.randomElement()!, from: self.user)
      }) {
        Text("Submit")
      }
      List {
        ForEach(posts) { post in
          PostView(post: post)
        }
      }
    }
  }
}

struct AllPostsView: View {
  
  @EnvironmentObject var session: Session
  
  private var posts: [Entity.Post] {
    session.store.state.db.entities.post.find(in: session.store.state.db.indexes.postIDs)
  }
    
  var body: some View {
    NavigationView {
      List {
        ForEach(posts) { post in
          PostView(post: post)
        }
      }
      .navigationBarTitle("Posts")
    }
  }
  
}

struct PostView: View {
  
  @EnvironmentObject var session: Session
  
  let post: Entity.Post
  
  private var user: Entity.User? {
    session.store.state.db.entities.user.find(by: post.userID)
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


