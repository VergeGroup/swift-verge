//
//  ActivityTests.swift
//  VergeStoreTests
//
//  Created by muukii on 2019/12/24.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import XCTest
import VergeStore

#if canImport(Combine)

import Combine

@available(iOS 13, macOS 10.15, *)
class ActivityTests: XCTestCase {
  
  struct State {
    
  }
  
  enum Activity {
    case didSendMessage
  }
  
  final class Store: StoreBase<State, Activity>, DispatcherType {
    
    var dispatchTarget: StoreBase<State, Activity> { self }
    
    init() {
      super.init(initialState: .init(), logger: DefaultLogger.shared)
    }
    
    func sendMessage() -> Action<Void> {
      return .action { context in
        context.send(.didSendMessage)
      }
    }
  }
  
  private var subscriptions = Set<AnyCancellable>()
  
  func testSend() {
    
    let store = Store()
    
    let waiter = XCTestExpectation()
    
    store
      .activityPublisher
      .sink { event in
        XCTAssertEqual(event, .didSendMessage)
        waiter.fulfill()
    }
    .store(in: &subscriptions)
    
    store.accept { $0.sendMessage() }
    
    wait(for: [waiter], timeout: 10)
        
  }
}

#endif
