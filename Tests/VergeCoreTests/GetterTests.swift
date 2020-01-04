//
//  GetterTests.swift
//  VergeCoreTests
//
//  Created by muukii on 2019/12/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import XCTest

@testable import VergeCore

class GetterTests: XCTestCase {
  
  func testMemoization() {
    
    let getter = Getter(
      input: 0,
      filter: EqualityComputer.init(),
      map: { $0 }
    )
    getter.addDidUpdate { (v) in
      XCTFail("It would not be called after created getter")
    }
    getter._receive(newValue: 0)
    
  }
  
  func testRatain() {
    
    var storage: Storage! = Storage<Int>(0)
    weak var storageRef = storage
    
    XCTAssertNotNil(storageRef)
    
    var _first: Getter! = storage.getter(filter: .alwaysDifferent(), map: { $0 })
               
    weak var firstRef = _first
          
    var second: AnyGetter! = firstRef!.map(transform: { $0 })
    
    XCTAssertEqual(second.value, 0)
    
    storage.replace(1)
    
    XCTAssertEqual(second.value, 1)
    
    XCTAssertNotNil(firstRef)

    _first = nil
    
    XCTAssertNotNil(firstRef) // Because, second ratains
        
    storage.replace(10)
    
    storage = nil
    
    XCTAssertNotNil(storageRef) // Because, first retains storage
    XCTAssertEqual(second.value, 10)
    
    second = nil
    
    XCTAssertNil(firstRef)
    XCTAssertNil(storageRef)
           
  }
  
  func testNonMemoization() {
    
    var count = 0
        
    let getter = Getter(
      input: 0,
      filter: .alwaysDifferent(),
      map: { $0 }
    )
    
    getter.addDidUpdate { (v) in
      count += 1
    }
    XCTAssert(count == 0)
    getter._receive(newValue: 0)
    XCTAssert(count == 1)
  }
}
