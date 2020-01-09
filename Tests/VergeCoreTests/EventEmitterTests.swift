//
//  EventEmitterTests.swift
//  VergeCoreTests
//
//  Created by muukii on 2019/12/21.
//  Copyright © 2019 muukii. All rights reserved.
//

import XCTest
import VergeCore

#if canImport(Combine)
import Combine
#endif

@available(iOS 13.0, *)
class EventEmitterTests: XCTestCase {
  
  private var subscriptions = Set<AnyCancellable>()
  
  @available(iOS 13, *)
  func testPublisher() {
    
    let emitter = EventEmitter<String>()
    
    let waiter = XCTestExpectation()
    
    emitter
      .publisher
      .handleEvents(receiveSubscription: { (sub) in
        print(sub)
      }, receiveOutput: { (value) in
        XCTAssertEqual(value, "Hello")
        waiter.fulfill()
      }, receiveCompletion: { (completion) in
        
      }, receiveCancel: {
        
      }, receiveRequest: { demand in
        
      })
      .makeConnectable()
      .connect()
      .store(in: &subscriptions)
    
    emitter.accept("Hello")
    
    wait(for: [waiter], timeout: 10)
  }
  
  @available(iOS 13, *)
  func testPublisherMultiple() {
    
    let emitter = EventEmitter<String>()
    
    let waiter1 = XCTestExpectation()
    let waiter2 = XCTestExpectation()
    let waiter3 = XCTestExpectation()
    
    emitter
      .publisher
      .sink { _ in
        waiter1.fulfill()
    }
    .store(in: &subscriptions)
    
    emitter
      .publisher
      .sink { _ in
        waiter2.fulfill()
    }
    .store(in: &subscriptions)
    
    emitter
      .publisher
      .sink { _ in
        waiter3.fulfill()
    }
    .store(in: &subscriptions)
    
    emitter.accept("Hello")
    
    wait(for: [waiter1, waiter2, waiter3], timeout: 10)
  }
  
  
}
