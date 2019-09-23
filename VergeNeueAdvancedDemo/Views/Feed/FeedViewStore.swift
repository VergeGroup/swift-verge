//
//  FeedViewStore.swift
//  VergeNeueAdvancedDemo
//
//  Created by muukii on 2019/09/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import VergeNeue

struct FeedViewState {
  
  var posts: [Store<PhotoDetailReducer>] = []
  
}

final class FeedViewReducer: ModularReducerType {
      
  typealias State = FeedViewState
  typealias ParentReducer = LoggedInReducer
  
  let service: Service
  
  init(service: Service) {
    self.service = service
  }
  
  func makeInitialState() -> FeedViewState {
    .init()
  }
  
  func parentChanged(newState: LoggedInState, store: Store<FeedViewReducer>) {
    
  }
  
  func fetchPosts() -> Action<Void> {
    Action<Void> { context in
      _ = self.service.fetchPhoto()
    }
  }
}
