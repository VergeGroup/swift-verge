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
  
  @ObservedObject var store: FeedViewStore
  
  @State var selectedValue: DynamicFeedPost?
  
  var body: some View {
    NavigationView {
      List(store.state.posts, selection: $selectedValue) { (store) in
        NavigationLink(destination: PhotoDetailView(store: store)) {
          self.cell(store: store)
        }
      }
      .navigationBarTitle("Feed")
      .navigationBarItems(trailing: HStack {
        Button(action: {
          self.store.fetchPosts()
        }) {
          Text("Load")
        }
      })
    }
    
  }
    
  private func cell(store: PhotoDetailStore) -> some View {
    
    HStack {
      NetworkImageView(url: URL(string: store.state.post.imageURLString.value)!)
        .frame(width: 100, height: 100, alignment: .center)
        .clipped()
      
      VStack {
        Text("ID")
          .font(.caption)
        Text(store.state.post.id)
          .font(.body)
          .fontWeight(.bold)
      }
      VStack {
        Text("Comments")
          .font(.caption)
        Text(store.state.comments.count.description)
          .font(.body)
          .fontWeight(.bold)
      }
    }
    
  }
}

