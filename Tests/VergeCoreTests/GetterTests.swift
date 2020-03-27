//
//  GetterTests.swift
//  VergeCoreTests
//
//  Created by muukii on 2020/01/10.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest
import VergeCore

import Combine

@available(iOS 13.0, *)
class GetterTests: XCTestCase {
  
  private var subs = Set<AnyCancellable>()
  
  func testFirstCall() {
    
    let storage = Storage<Int>(1)
    
    var updateCount = 0
    
    let g = storage.makeGetter(from: .make(
      preFilter: .init(),
      transform: { $0 * 2 })
    )
        
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
    
    let storage = Storage<Int>(1)
    
    var updateCount = 0
    
    let g = storage.makeGetter().changed().map { $0 * 2 }.build()
                                 
    g.sink { _ in
      updateCount += 1
    }
    .store(in: &subs)
       
    XCTAssertEqual(g.value, 2)
    
    storage.update {
      $0 = 2
    }
    
    XCTAssertEqual(storage.value, 2)
    
    XCTAssertEqual(g.value, 4)
    
    storage.update {
      $0 = 2
    }
    
    storage.update {
      $0 = 2
    }
    
    XCTAssertEqual(updateCount, 2)
    
  }
  
  func testChain() {
    
    let storage = Storage<Int>(1)
    
    var first: GetterSource<Int, Int>! = storage.makeGetter(from: .make(
      preFilter: .init(),
      transform: { $0 })
    )
    
    weak var weakFirst = first
    
    var second: Getter! = Getter {
      first
        .map { $0 }
    }
    
    XCTAssertNotNil(weakFirst)
    XCTAssertEqual(second.value, 1)
    
    first = nil
    
    XCTAssertNotNil(weakFirst)
    
    storage.update {
      $0 = 2
    }
    
    XCTAssertEqual(second.value, 2)
    
    second = nil
    
    let waiter = XCTestExpectation()
    
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
      
      XCTAssertNil(weakFirst)
      waiter.fulfill()
    }
    
    wait(for: [waiter], timeout: 2)
  }
  
  func testShare() {
    
    let storage = Storage<Int>(1)
    
    let first = storage.makeGetter()
      .changed()
      .noMap()
      .build()
        
    let share1 = Getter {
      first.map { $0 }
    }
    
    let share2 = Getter {
      first.map { $0 }
    }
    
    XCTAssertEqual(share1.value, 1)
    XCTAssertEqual(share2.value, 1)
    
    storage.update {
      $0 = 2
    }
    
    XCTAssertEqual(share1.value, 2)
    XCTAssertEqual(share2.value, 2)
    
  }
  
  func testCombine() {
    
    let storage = Storage<Int>(1)
    
    let first = storage.makeGetter(from: .make(
      preFilter: .init(
        keySelector: { $0 },
        comparer: .init { $0 == $1 }
      ),
      transform: { $0 })
    )
    
    let second = storage.makeGetter(from: .make(
      preFilter: .init(
        keySelector: { $0 },
        comparer: .init { $0 == $1 }
      ),
      transform: { -$0 })
    )
    
    let combined = Getter {
      first.combineLatest(second)
        .map { $0 + $1 }
        .removeDuplicates()
    }
    
    XCTAssertEqual(combined.value, 0)
    
  }
  
  func testPostFilter() {
    
    let storage = Storage<Int>(1)
    
    let getter = storage.makeGetter()
      .map(\.description)
      .changed(comparer: .init(==))
      .build()
          
    var updateCount = 0
    
    getter.sink { _ in
      updateCount += 1
    }
    .store(in: &subs)
    
    XCTAssertEqual(updateCount, 1)
    
    storage.update {
      $0 = 2
    }
    
    storage.update {
      $0 = 2
    }
    
    storage.update {
      $0 = 2
    }
    
    XCTAssertEqual(updateCount, 2)
    
    storage.update {
      $0 = 3
    }
    
    XCTAssertEqual(updateCount, 3)
    
  }
  
}
