//
//  GetterTests.swift
//  VergeCoreTests
//
//  Created by muukii on 2019/12/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeCore

class GetterTests: XCTestCase {
  
  func testMemoization() {
    
    let getter = Getter(initialSource: 0, selector: { $0 }, equality: .init(), memoizes: true, onDeinit: {})
    getter.addDidUpdate { (v) in
      XCTFail()
    }
    getter._accept(sourceValue: 0)
    
  }
  
  func testNonMemoization() {
    
    var count = 0
    let getter = Getter(initialSource: 0, selector: { $0 }, equality: .init(), memoizes: false, onDeinit: {})
    getter.addDidUpdate { (v) in
      count += 1
    }
    XCTAssert(count == 0)
    getter._accept(sourceValue: 0)
    XCTAssert(count == 1)
  }
}
