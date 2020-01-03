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
      XCTFail()
    }
    getter._receive(newValue: 0)
    
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
