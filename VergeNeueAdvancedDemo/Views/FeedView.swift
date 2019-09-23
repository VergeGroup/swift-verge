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
  
  @ObservedObject var store: Store<LoggedInReducer>
  
  @State var selectedValue: DynamicFeedPost?
  
  var body: some View {
    NavigationView {
      List(store.state.fetchedPosts, selection: $selectedValue) { (item) in
        NavigationLink(destination: IssueDetailView(store: self.store, post: item)) {
          issueCell(issue: item)
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
}

fileprivate func issueCell(issue: DynamicFeedPost) -> some View {
  
  ZStack {
    VStack {
      NetworkImageView(url: URL(string: issue.imageURLString.value)!)
        .frame(width: 100, height: 100, alignment: .center)
        .clipped()
    }
  }
}
