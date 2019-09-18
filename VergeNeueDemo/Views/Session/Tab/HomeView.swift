//
//  HomeView.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import VergeNeue

struct HomeView: View {
  
  @EnvironmentObject var sessionStore: SessionStateReducer.StoreType
      
  var body: some View {
    NavigationView {
      List(sessionStore.state.photosForHome) { (photo) in
        Self.Cell(photo: photo, comments: self.sessionStore.state.comments(for: photo.id))
      }
      .navigationBarTitle("Home")
    }
    .onAppear {
      self.sessionStore.dispatch { $0.fetchPhotos() }
    }
  }
}

extension HomeView {
  
  fileprivate static func Cell(photo: Photo, comments: [Comment]) -> some View {
    
    VStack {
      
      NetworkImageView(url: photo.url)
        .frame(width: nil, height: 120, alignment: .top)
        .clipped()
                
      Text(photo.id)
      
      Text("Comments:")
      
      ForEach(comments) { comment in
        Text(comment.body)
      }
        
    }
    
  }
  
}
