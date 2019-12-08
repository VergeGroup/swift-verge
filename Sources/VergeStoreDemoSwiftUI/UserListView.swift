//
//  UserListView.swift
//  VergeStoreDemoSwiftUI
//
//  Created by muukii on 2019/12/08.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import SwiftUI

struct UserListView: View {
  
  @EnvironmentObject var session: Session
  
  private var users: AnyRandomAccessCollection<Entity.User> {
    // Experimental using lazy
    AnyRandomAccessCollection(
      session.store.state.userIDs.lazy.compactMap {
        self.session.store.state.entity.user.find(by: $0)
      }
    )
  }
      
  var body: some View {
    NavigationView {
      List {
        ForEach(users) { user in
          NavigationLink(destination: SubmitView(user: user)) {
            Text(user.name)
          }
        }
      }
      .navigationBarTitle("Users")
    }
    .edgesIgnoringSafeArea(.all)      
    .onAppear {
      self.session.sessionDispatcher.accept { $0.insertSampleUsers() }
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
    session.store.state.entity.post.find(in: session.store.state.postIDsByUser[user.id] ?? [])
  }
  
  var body: some View {
    VStack {
      Button(action: {
        self.session.sessionDispatcher.accept { $0.submitNewPost(title: self.samples.randomElement()!, from: self.user) }
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
    session.store.state.entity.post.find(in: session.store.state.postIDs)
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
    .edgesIgnoringSafeArea(.all)
  }
  
}

struct PostView: View {
  
  @EnvironmentObject var session: Session
  
  let post: Entity.Post
  
  private var user: Entity.User? {
    session.store.state.entity.user.find(by: post.userID)
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


