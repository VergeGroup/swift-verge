//
//  EventEmitterTests.swift
//  VergeCoreTests
//
//  Created by muukii on 2019/12/21.
//  Copyright © 2019 muukii. All rights reserved.
//

import XCTest
@_spi(EventEmitter) import Verge

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
  
  
  func testRegistrationPerformance() {
    
    let emitter = EventEmitter<Void>()
    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      for _ in 0..<1000 {
        emitter.addEventHandler { _ in
          
        }
      }
    }
    
  }

  func testEmittingPerformance() {

    let emitter = EventEmitter<Void>()

    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()]) {
      for _ in 0..<10000 {
        emitter.accept(())
      }
    }

  }

  func testOrder() {

    let emitter = EventEmitter<Int>()

    var results_1 = [Int]()
    emitter.addEventHandler { value in
      results_1.append(value)

      if value == 1 {
        emitter.accept(2)
      }
    }

    var results_2 = [Int]()
    emitter.addEventHandler { value in
      results_2.append(value)
    }

    emitter.accept(1)

    XCTAssertEqual(results_1, [1, 2])
    XCTAssertEqual(results_2, [1, 2])

  }

  func testEmitsAll() {

    let emitter = EventEmitter<Int>()

    emitter.addEventHandler { value in
    }

    let outputs = VergeConcurrency.UnfairLockAtomic.init([Int]())
    emitter.addEventHandler { value in
      outputs.modify({
        $0.append(value)
      })
    }

    let inputs = VergeConcurrency.UnfairLockAtomic.init([Int]())
    DispatchQueue.concurrentPerform(iterations: 500) { i in
      inputs.modify {
        $0.append(i)
      }
      emitter.accept(i)
    }

    XCTAssertEqual(outputs.value.count, 500)

  }

}
