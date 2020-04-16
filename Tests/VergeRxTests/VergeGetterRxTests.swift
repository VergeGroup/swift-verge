//
//  VergeGetterRxTests.swift
//  VergeGetterRxTests
//
//  Created by muukii on 2020/01/09.
//  Copyright © 2020 muukii. All rights reserved.
//

import XCTest

import RxSwift

import VergeStore
import VergeRx

extension Int : StateType {}

class VergeGetterRxTests: XCTestCase {
  
  func testConstant() {
    
    let getter = RxGetter<String>.constant("Hello")
    
    let waiter = XCTestExpectation()
    
    _ = getter.bind { value in
      XCTAssertEqual(value, "Hello")
      waiter.fulfill()
    }
    
    wait(for: [waiter], timeout: 1)
    
  }
    
  func testSimpleWithSubscribe() {

    let storage = Store<Int, Never>.init(initialState: 1, logger: nil)
    
    var updateCount = 0
                
    let g = storage.rx.getterBuilder().changed(comparer: .init(==))
      .map { $0 * 2 }
      .build()
        
    _ = g.subscribe(onNext: { _ in
      updateCount += 1
    })
        
    XCTAssertEqual(g.value, 2)

    storage.commit {
      $0 = 2
    }
    
    XCTAssertEqual(storage.state, 2)
    
    XCTAssertEqual(g.value, 4)
    
    storage.commit {
      $0 = 2
    }
    
    storage.commit {
      $0 = 2
    }
    
    storage.commit {
      $0 = 2
    }
    
    XCTAssertEqual(updateCount, 2)
    
  }
  
  func testSimpleWithBind() {
    
    let storage = Store<Int, Never>.init(initialState: 1, logger: nil)
    
    var updateCount = 0
        
    let g = storage.rx.getterBuilder()
      .changed(comparer: .init(==))
      .map { $0 * 2 }
      .build()
    
    _ = g.bind { _ in
      updateCount += 1
    }
    
    XCTAssertEqual(g.value, 2)
    
    storage.commit {
      $0 = 2
    }
    
    XCTAssertEqual(storage.state, 2)
    
    XCTAssertEqual(g.value, 4)
    
    storage.commit {
      $0 = 2
    }
    
    storage.commit {
      $0 = 2
    }
    
    storage.commit {
      $0 = 2
    }
    
    XCTAssertEqual(updateCount, 2)
    
  }
  
  func testChain() {
    
    let storage = Store<Int, Never>.init(initialState: 1, logger: nil)
                 
    var first: RxGetterSource<Int, Int>! = storage.rx.getterBuilder()
      .changed(comparer: .init(==))
      .map { $0 }
      .build()
    
    weak var weakFirst = first
                
    var second: RxGetter! = RxGetter {
      first
        .map { $0 }
    }
    
    XCTAssertNotNil(weakFirst)
    XCTAssertEqual(second.value, 1)
    
    first = nil
    
    XCTAssertNotNil(weakFirst)
    
    storage.commit {
      $0 = 2
    }
    
    XCTAssertEqual(second.value, 2)
    
    second = nil
    
    XCTAssertNil(weakFirst)

  }
  
  func testShare() {
    
    let storage = Store<Int, Never>.init(initialState: 1, logger: nil)
            
    let first: RxGetterSource<Int, Int>! = storage.rx.getterBuilder()
      .changed(comparer: .init(==))
      .map { $0 }
      .build()
    
    let share1 = RxGetter {
      first.map { $0 }
    }
    
    let share2 = RxGetter {
      first.map { $0 }
    }
    
    XCTAssertEqual(share1.value, 1)
    XCTAssertEqual(share2.value, 1)
    
    storage.commit {
      $0 = 2
    }
    
    XCTAssertEqual(share1.value, 2)
    XCTAssertEqual(share2.value, 2)
    
  }
  
  func testCombine() {
    
    let storage = Store<Int, Never>.init(initialState: 1, logger: nil)
    
    let first = storage.rx.getterBuilder()
      .changed(comparer: .init(==))
      .map { $0 }
      .build()
        
    let second = storage.rx.getterBuilder()
      .changed(comparer: .init(==))
      .map { -$0 }
      .build()
            
    let combined = RxGetter {
      Observable.combineLatest(first, second)
        .map { $0 + $1 }
        .distinctUntilChanged()
    }
        
    XCTAssertEqual(combined.value, 0)
      
  }
  
}
