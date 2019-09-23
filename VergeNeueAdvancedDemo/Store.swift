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

struct LoggedInState {
  
}

final class LoggedInStore: StoreBase<LoggedInState> {
  
  
  let feedStore: FeedViewStore
  
  let mypageStore: MyPageViewStore
  
  init(service: Service) {
    
    self.feedStore = .init(service: service)
    self.mypageStore = .init(service: service)
    
    super.init(initialState: .init(), logger: MyStoreLogger.default)
    
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

