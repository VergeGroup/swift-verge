//
//  PhotoDetailStore.swift
//  VergeNeueAdvancedDemo
//
//  Created by muukii on 2019/09/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import CoreStore

import VergeStore

struct PhotoDetailState {
  
  let post: DynamicFeedPost
  var comments: [DynamicFeedPostComment] = []
}

final class PhotoDetailStore: StoreBase<PhotoDetailState>, ListObserver {
  
  typealias ListEntityType = DynamicFeedPostComment
    
  let service: Service
  
  private let listMonitor: ListMonitor<DynamicFeedPostComment>
 
  init(service: Service, post: DynamicFeedPost) {
    
    self.service = service
    
    self.listMonitor = service.coreStore.monitorList(
      From<DynamicFeedPostComment>()
        .orderBy(.descending(\.updatedAt))
        .where(\.post == post)
    )
    
    super.init(initialState: .init(post: post), logger: MyStoreLogger.default)
    
    self.listMonitor.addObserver(self)
    
    commit {
      $0.comments = self.listMonitor.objectsInAllSections()
    }
  }
      
  func addAnyComment() {
    dispatch { c in
      _ = service.addComment(body: Lorem.title, target: c.state.post)
    }
  }
  
  func listMonitorDidChange(_ monitor: ListMonitor<DynamicFeedPostComment>) {
    commit {
      $0.comments = monitor.objectsInAllSections()
    }
  }
  
  func listMonitorDidRefetch(_ monitor: ListMonitor<DynamicFeedPostComment>) {
    
  }
    
}
