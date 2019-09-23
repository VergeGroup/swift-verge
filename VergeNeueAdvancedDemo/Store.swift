//
//  Store.swift
//  Verge
//
//  Created by muukii on 2019/09/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import SwiftUI
import VergeNeue
import CoreStore
import Combine

extension DynamicFeedPost: Swift.Identifiable {
  public var id: String {
    rawID.value
  }
}

struct LoggedInReducer: ReducerType {
   
  struct State {
    
    struct Me {
      
      var accountName: String = "muukii.app"
      
      var introduction: String = "I'm an iOS Developer"
      
      var postCount: Int = 123
      var followerCount: Int = 379
      var followingCount: Int = 1000
    }
    
    let feedStore: Store<FeedViewReducer>
    
    var me: Me = .init()
    
  }
  
  let service: Service
  private var subscriptions = Set<AnyCancellable>()
  
  init(service: Service) {
    self.service = service
  }
  
  func makeInitialState() -> State {
    .init(feedStore: .init(reducer: .init(service: service), registerParent: self))
  }
      
  func addNewComment(target item: DynamicFeedPost) -> Action<Void> {
    Action<Void> { context in
      
      _ = self.service.addComment(body: Lorem.title, target: item)
      
      /**
       self.service.coreStore.fetchAll(From<DynamicFeedPostComment>()
       .orderBy(.descending(\.updatedAt))
       .where(\.post == self.issue))
       */
      
    }
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

