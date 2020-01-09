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
    
  func testSimple() {

    let storage = Storage<Int>(1)
    
    var updateCount = 0
    
    let g = storage.rx.getter(filter: .init(), map: { $0 * 2})
    
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
    
    XCTAssertEqual(updateCount, 2)
    
  }
  
  func testChain() {
    
    let storage = Storage<Int>(1)
        
    var first: RxGetterSource<Int, Int>! = storage.rx.getter(filter: .init(), map: { $0 })
    
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
  
  func testCombine() {
    
    let storage = Storage<Int>(1)
    
    let first = storage.rx.getter(filter: .init(), map: { $0 })
    let second = storage.rx.getter(filter: .init(), map: { -$0 })
    
    let combined = RxGetter {
      Observable.combineLatest(first, second)
        .map { $0 + $1 }
        .distinctUntilChanged()
    }
        
    XCTAssertEqual(combined.value, 0)
      
  }
  
}
