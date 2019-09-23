//
//  FeedViewStore.swift
//  VergeNeueAdvancedDemo
//
//  Created by muukii on 2019/09/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import VergeStore
import CoreStore

struct FeedViewState {
  
  var posts: [PhotoDetailStore] = []
  
}

final class FeedViewStore: StoreBase<FeedViewState>, ListObserver {
  
  typealias ListEntityType = DynamicFeedPost
     
  let service: Service
  private let listMonitor: ListMonitor<ListEntityType>
  
  init(service: Service) {
    self.service = service
        
    self.listMonitor = service.coreStore.monitorList(
      From<ListEntityType>()
        .orderBy(.ascending(\.updatedAt))
    )

    super.init(initialState: .init(), logger: MyStoreLogger.default)
    
    self.listMonitor.addObserver(self)
  }
    
  func fetchPosts() {
    dispatch { context in
      _ = service.fetchPhoto()
    }
  }
  
  func listMonitorDidChange(_ monitor: ListMonitor<DynamicFeedPost>) {
    // Diff
    commit { state in
      state.posts += monitor.objectsInAllSections().filter { object in
        !state.posts.contains { $0.state.post == object }
      }
      .map {
        PhotoDetailStore(service: service, post: $0)
      }
    
    }
  }
  
  func listMonitorDidRefetch(_ monitor: ListMonitor<DynamicFeedPost>) {
    
  }
}
