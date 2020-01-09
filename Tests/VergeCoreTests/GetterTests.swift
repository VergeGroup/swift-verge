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
  
  func testSimple() {
    
    let storage = Storage<Int>(1)
    
    var updateCount = 0
    
    let g = storage.getter(filter: .init(), map: { $0 * 2})
    
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
    
    XCTAssertEqual(updateCount, 2)
    
  }
  
  func testChain() {
    
    let storage = Storage<Int>(1)
    
    var first: GetterSource<Int, Int>! = storage.getter(filter: .init(), map: { $0 })
    
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
    
    XCTAssertNil(weakFirst)
    
  }
  
  func testCombine() {
    
    let storage = Storage<Int>(1)
    
    let first = storage.getter(filter: .init(), map: { $0 })
    let second = storage.getter(filter: .init(), map: { -$0 })
    
    let combined = Getter {
      first.combineLatest(second)
        .map { $0 + $1 }
        .removeDuplicates()
    }
    
    XCTAssertEqual(combined.value, 0)
    
  }
  
}
