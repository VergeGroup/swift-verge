//
//  Store.swift
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

extension DynamicFeedPost: Swift.Identifiable {
  public var id: String {
    rawID.value
  }
}

struct NormalizedState {
  
  var me: Me = .init()
  var posts: [SnapshotFeedPost.ID : SnapshotFeedPost] = [:]
  var comments: [SnapshotFeedPostComment.ID : SnapshotFeedPostComment] = [:]
  var users: [SnapshotUser.ID : SnapshotUser] = [:]
}

struct LoggedInState {
  
  struct Feed {
    var fetched: [SnapshotFeedPost.ID] = []
  }
  
  var normalizedState: NormalizedState = .init()
  
  var feed: Feed = .init()
  
}

final class LoggedInStore: StateNode<LoggedInState> {
    
  let service: Service
  
  private var proxies: [AnyObject] = []
  private var listMonitors: [AnyObject] = []
  
  private var subscriptions: Set<AnyCancellable> = .init()
  
  init(service: Service) {
    
    self.service = service
    
    super.init(initialState: .init(), logger: nil)
    
    startIntegrationWithCoreData()
  }
  
  func fetchPosts() {
    dispatch { context in
      service.fetchPhoto()
        .sink(receiveCompletion: { (completion) in
          
        }) { [weak self] (values) in
          
          guard let self = self else { return }
          
          self.commit {
            $0.feed.fetched += values
          }
          
      }
      .store(in: &subscriptions)
    }
  }
  
  func addAnyComment(to post: SnapshotFeedPost) {
    dispatch { c in    
      _ = self.service.addComment(body: Lorem.title, target: post)
    }
  }
  
  private func startIntegrationWithCoreData() {
    
    let coreStore = service.coreStore
    
    do {
      let proxy = ListObserverProxy<DynamicFeedPost>()
      let monitor = coreStore.monitorList(From<DynamicFeedPost>().orderBy(.descending(\.updatedAt)))
      monitor.addObserver(proxy)
      proxy.onChanged = { [weak self] items in
        
        guard let self = self else { return }
        
        self.commit { state in
          items.forEach { item in
            let snapshot = SnapshotFeedPost(source: item)
            state.normalizedState.posts[snapshot.id] = snapshot
          }
        }
      }
      
      proxies.append(proxy)
      listMonitors.append(monitor)
      
    }
       
    do {
      
      let proxy = ListObserverProxy<DynamicFeedPostComment>()
      let monitor = coreStore.monitorList(From<DynamicFeedPostComment>().orderBy(.descending(\.updatedAt)))
      monitor.addObserver(proxy)
      proxy.onChanged = { [weak self] items in
        
        guard let self = self else { return }
        
        self.commit { state in
//          items.forEach { item in
//            let snapshot = SnapshotFeedPostComment(source: item)
//            state.normalizedState.comments[snapshot.id] = snapshot
//          }
        }
      }
      
      proxies.append(proxy)
      listMonitors.append(monitor)

      
    }
    
    do {
      let proxy = ListObserverProxy<DynamicUser>()
      let monitor = coreStore.monitorList(From<DynamicUser>().orderBy(.descending(\.updatedAt)))
      monitor.addObserver(proxy)
      proxy.onChanged = { [weak self] items in
        
        guard let self = self else { return }
        
        self.commit { state in
          items.forEach { item in
            let snapshot = SnapshotUser(source: item)
            state.normalizedState.users[snapshot.id] = snapshot
          }
        }
      }
      
      proxies.append(proxy)
      listMonitors.append(monitor)

    }
    
    
  }
    
}

final class ListObserverProxy<T: CoreStoreObject>: ListObserver {
  
  var onChanged: ([T]) -> Void = { _ in }
  
  init() {
    
  }
  
  deinit {
    print("deinit", self)
  }
  
  typealias ListEntityType = T
  
  func listMonitorDidChange(_ monitor: ListMonitor<T>) {
    onChanged(monitor.objectsInAllSections())
  }
  
  func listMonitorDidRefetch(_ monitor: ListMonitor<T>) {
    
  }
}


//final class ExternalDataIntegrationAdapter: AdapterBase<LoggedInReducer>, ListObserver {
//  
//  typealias ListEntityType = DynamicFeedPost
//  
//  private let listMonitor = CoreStore.monitorList(From<DynamicFeedPost>().orderBy(.descending(\.updatedAt)))
//  
//  override init() {
//    
//    super.init()
//    
//    self.listMonitor.addObserver(self)
//  }
//  
//  func listMonitorDidChange(_ monitor: ListMonitor<DynamicFeedPost>) {
//    
//    run { (store) in
//      
//      store.dispatch { _ in
//        Action<Void> { c in
//          guard c.state.fetchedPosts != monitor.objectsInAllSections() else { return }
//          c.commit { _ in
//            Mutation { s in
//              s.fetchedPosts = monitor.objectsInAllSections()
//            }
//          }
//        }
//        
//      }
//      
//    }
//  }
//  
//  func listMonitorDidRefetch(_ monitor: ListMonitor<DynamicFeedPost>) {
//    
//  }
//  
//}
//

