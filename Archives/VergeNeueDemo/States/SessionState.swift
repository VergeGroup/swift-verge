//
//  SessionState.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import Combine

import VergeNeue

struct SessionState {
  
  let env: Env
  
  var photosStorage: [Photo.ID : Photo] = [:]
  var notificationStorage: [Notification.ID : Notification] = [:]
  var commentsStorage: [Comment.ID : Comment] = [:]
    
  var photosIdForHome: [Photo.ID] = []
  
  var photosForHome: [Photo] {
    photosIdForHome.compactMap {
      photosStorage[$0]
    }
  }
  
  func comments(for photoID: Photo.ID) -> [Comment] {
    commentsStorage.filter { $0.value.photoID == photoID }.map { $0.value }
  }
    
  var notificationIds: [Notification.ID] = []
  
  var notifications: [Notification] {
    notificationIds.compactMap {
      notificationStorage[$0]
    }
  }
        
  var count: Int = 0  
}
