//
//  GetterTests.swift
//  VergeCoreTests
//
//  Created by muukii on 2020/01/10.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest
import VergeStore

import Combine

extension Int: StateType {}

@available(iOS 13.0, *)
class GetterTests: XCTestCase {
    
  private var subs = Set<AnyCancellable>()
       
  func testFirstCall() {
    
    let store = Store<Int, Never>.init(initialState: 1, logger: nil)
    
    var updateCount = 0
      
    let g = store.getterBuilder().changed().map { $0 * 2 }.build()
        
    g.sink { _ in
      updateCount += 1
    }
    .store(in: &subs)
          
    XCTAssertEqual(updateCount, 1)

  }
  
  func testConstant() {
    
    let getter = Getter<String>.constant("Hello")
    
    let waiter = XCTestExpectation()
    
    getter.sink { value in
      XCTAssertEqual(value, "Hello")
      waiter.fulfill()
    }
    .store(in: &subs)
    
    wait(for: [waiter], timeout: 1)
  }
  
  func testSimple() {
    
    let storage = Store<Int, Never>.init(initialState: 1, logger: nil)
    
    var updateCount = 0
    
    let g = storage.getterBuilder().changed().map { $0 * 2 }.build()
                                 
    g.sink { _ in
      updateCount += 1
    }
    .store(in: &subs)
       
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
    
    XCTAssertEqual(updateCount, 2)
    
  }
  
  func testChain() {
    
    let storage = Store<Int, Never>.init(initialState: 1, logger: nil)
    
    var first: GetterSource<Int, Int>! = storage.getterBuilder().changed().map { $0 }.build()
          
    weak var weakFirst = first
    
    var second: Getter! = Getter {
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
    
    let waiter = XCTestExpectation()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      
      XCTAssertNil(weakFirst)
      waiter.fulfill()
    }
    
    wait(for: [waiter], timeout: 2)
  }
  
  func testShare() {
    
    let storage = Store<Int, Never>.init(initialState: 1, logger: nil)
    
    let first = storage.getterBuilder()
      .changed()
      .map { $0 }
      .build()
        
    let share1 = Getter {
      first.map { $0 }
    }
    
    let share2 = Getter {
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
    
    let first = storage.getterBuilder().changed().map { $0 }.build()
            
    let second = storage.getterBuilder().changed().map { -$0 }.build()
    
    let combined = Getter {
      first.combineLatest(second)
        .map { $0 + $1 }
        .removeDuplicates()
    }
    
    XCTAssertEqual(combined.value, 0)
    
  }
  
  func testPostFilter() {
    
    let storage = Store<Int, Never>.init(initialState: 1, logger: nil)
    
    let getter = storage.getterBuilder()
      .map(\.description)
      .changed(comparer: .init(==))
      .build()
          
    var updateCount = 0
    
    getter.sink { _ in
      updateCount += 1
    }
    .store(in: &subs)
    
    XCTAssertEqual(updateCount, 1)
    
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
    
    storage.commit {
      $0 = 3
    }
    
    XCTAssertEqual(updateCount, 3)
    
  }
  
}
