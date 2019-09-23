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
  
  @ObservedObject var store: Store<FeedViewReducer>
  
  @State var selectedValue: DynamicFeedPost?
  
  var body: some View {
    NavigationView {
      List(store.state.posts, selection: $selectedValue) { (post) in
        NavigationLink(destination: PhotoDetailView(store: store)) {
          self.cell(post: post)
        }
      }
      .navigationBarTitle("Feed")
      .navigationBarItems(trailing: HStack {
        Button(action: {
          self.store.dispatch { $0.fetchPosts() }
        }) {
          Text("Load")
        }
      })
    }
    
  }
    
  private func cell(post: DynamicFeedPost) -> some View {
    
    ZStack {
      VStack {
        NetworkImageView(url: URL(string: issue.imageURLString.value)!)
          .frame(width: 100, height: 100, alignment: .center)
          .clipped()
      }
    }
  }
}

