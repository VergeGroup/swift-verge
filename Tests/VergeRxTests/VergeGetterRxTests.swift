//
//  VergeGetterRxTests.swift
//  VergeGetterRxTests
//
//  Created by muukii on 2020/01/09.
//  Copyright © 2020 muukii. All rights reserved.
//

import XCTest

import RxSwift

import VergeCore
import VergeRx

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
    
  func testSimple() {

    let storage = Storage<Int>(1)
    
    var updateCount = 0
            
    let g = storage.rx.makeGetter {
      $0.preFilter(comparer: .init(==))
        .map { $0 * 2 }
    }
        
    _ = g.subscribe(onNext: { _ in
      updateCount += 1
    })
        
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
    
    storage.update {
      $0 = 2
    }
    
    XCTAssertEqual(updateCount, 2)
    
  }
  
  func testChain() {
    
    let storage = Storage<Int>(1)
                 
    var first: RxGetterSource<Int, Int>! = storage.rx.makeGetter {
      $0.preFilter(comparer: .init(==))
        .map { $0 * 2 }
    }
    
    weak var weakFirst = first
                
    var second: RxGetter! = RxGetter {
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
    
    XCTAssertNil(weakFirst)

  }
  
  func testShare() {
    
    let storage = Storage<Int>(1)
            
    let first: RxGetterSource<Int, Int>! = storage.rx.makeGetter {
      $0.preFilter(comparer: .init(==))
        .map { $0 * 2 }
    }
    
    let share1 = RxGetter {
      first.map { $0 }
    }
    
    let share2 = RxGetter {
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
    
    let first = storage.rx.makeGetter {
      $0.preFilter(comparer: .init(==))
        .map(\.self)
    }
        
    let second = storage.rx.makeGetter {
      $0.preFilter(comparer: .init(==))
        .map { -$0 }
    }
            
    let combined = RxGetter {
      Observable.combineLatest(first, second)
        .map { $0 + $1 }
        .distinctUntilChanged()
    }
        
    XCTAssertEqual(combined.value, 0)
      
  }
  
}
