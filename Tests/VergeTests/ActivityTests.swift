//
//  ActivityTests.swift
//  VergeStoreTests
//
//  Created by muukii on 2019/12/24.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import XCTest
import Verge

#if canImport(Combine)

import Combine

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
class ActivityTests: XCTestCase {
  
  struct Value: Equatable {
    
  }
  
  enum Activity {
    case didSendMessage
  }
  
  final class Store: Verge.Store<Value, Activity>, @unchecked Sendable {
        
    init() {
      super.init(initialState: .init(), logger: DefaultStoreLogger.default)
    }
    
    func sendMessage() {
      send(.didSendMessage)
    }
  }
  
  private var subscriptions = Set<AnyCancellable>()
  
  func testSend() {
    
    let store = Store()
    
    let waiter = XCTestExpectation()
    waiter.expectedFulfillmentCount = 1

    store
      .activityPublisher()
      .sink { event in
        XCTAssertEqual(event, .didSendMessage)
        waiter.fulfill()
    }
    .store(in: &subscriptions)
    
    store.sendMessage()
    
    wait(for: [waiter], timeout: 10)
        
  }
}

#endif
