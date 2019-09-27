//
//  FeedView.swift
//  Verge
//
//  Created by muukii on 2019/09/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import SwiftUI

import VergeNeue

struct FeedView: View {
    
  @EnvironmentObject var rootStore: LoggedInStore
  
  @State var selectedValue: DynamicFeedPost?
  
  private var fetchedItems: [SnapshotFeedPost] {
    rootStore.state.feed.fetched.compactMap { id in
      rootStore.state.normalizedState.posts[id]
    }
  }
    
  var body: some View {
        
    return NavigationView {
      List(fetchedItems) { item in
        NavigationLink(destination: PhotoDetailView(post: item) ) {
          PostListCell(post: item)
        }
      }
      .navigationBarTitle("Feed")
      .navigationBarItems(trailing: HStack {
        Button(action: {
          self.rootStore.fetchPosts()  
        }) {
          Text("Load")
        }
      })
        .onAppear {
          print("onappear", self)
      }
    }
    
  }
 
}

struct PostListCell: View {
  
  @EnvironmentObject var rootStore: LoggedInStore
  
  let post: SnapshotFeedPost
  
  private var commentsCount: Int {
    post.commentIDs.count
  }
    
  var body: some View {
    
    HStack {
      NetworkImageView(url: URL(string: post.imageURLString)!)
        .frame(width: 100, height: 100, alignment: .center)
        .clipped()
      
      VStack {
        Text("ID")
          .font(.caption)
        Text(post.id)
          .font(.body)
          .fontWeight(.bold)
      }
      VStack {
        Text("Comments")
          .font(.caption)
        Text(commentsCount.description)
          .font(.body)
          .fontWeight(.bold)
      }
    }
    
    
  }
}

