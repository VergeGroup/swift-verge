//
//  PhotoDetailStore.swift
//  VergeNeueAdvancedDemo
//
//  Created by muukii on 2019/09/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import VergeNeue

struct PhotoDetailState {
  
  let post: DynamicFeedPost
  var comments: [DynamicFeedPostComment] = []
}

struct PhotoDetailReducer: ModularReducerType {
    
  typealias State = PhotoDetailState
  typealias ParentReducer = FeedViewReducer
  
  let service: Service
  let photo: DynamicFeedPost
     
  func makeInitialState() -> PhotoDetailState {
    .init(post: photo)
  }
  
  func parentChanged(newState: FeedViewState, store: Store<PhotoDetailReducer>) {
    
  }
  
}
