//
//  PhotoDetailView.swift
//  Verge
//
//  Created by muukii on 2019/09/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import SwiftUI
import VergeStore
import CoreStore
import Combine

struct PhotoDetailView: View {
  
  @EnvironmentObject var store: LoggedInStore
  @State var hasFirstApearBeenDone: Bool = false
  @State private var displayComments: [SnapshotFeedPostComment] = []
    
  @State private var previousPost: SnapshotFeedPost? = nil
  var post: SnapshotFeedPost
  
  @discardableResult
  private func fetchDisplayComments() -> Future<[SnapshotFeedPostComment], Never> {
    .init { promise in
      
      print("Fetch Comments from", self.post.id)
      
      let comments = self.store.state.normalizedState.comments

      DispatchQueue.global(qos: .userInitiated).async {
        let result = comments
          .filter { $0.value.postID == self.post.id }
          .map { $0.value }
          .sorted { $0.updatedAt > $1.updatedAt }
        
        // bad practice, should have checked before querying.
        if self.displayComments != result {
          self.displayComments = result
        }
        
        promise(.success(result))
      }
    }
  }
          
  var body: some View {
    
    fetchDisplayComments()
    
    return VStack {
      List {
        ForEach(displayComments) { item in
          Text("\(item.body ?? "none")")
        }
      }
    }
    .navigationBarTitle("Comments")
    .navigationBarItems(trailing: HStack {
      Button(action: {
        self.store.addAnyComment(to: self.post)
      }) {
        Text("Add")
      }
      })
      .onAppear {
        
        if !self.hasFirstApearBeenDone {
          self.hasFirstApearBeenDone = true
         
        }
        
    }
    .onDisappear {
      print("disappear")
    }
  }
  
}
