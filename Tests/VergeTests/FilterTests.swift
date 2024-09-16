//
//  FilterTests.swift
//  VergeCoreTests
//
//  Created by muukii on 2020/01/14.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest

import Verge

final class FilterTests: XCTestCase {
    
  func testCombinedFilterOR() {
    
    struct Model {
      var a = 0
      var b = 0
      var c = 0
    }

    let comparison = OrComparator<Model, _, _>(
      .any { @Sendable in $0.a == 1 && $1.a == 1 },
      .any { @Sendable in  $0.b == 1 && $1.b == 1 }
    )
    .or(.any { @Sendable in $0.c == 1 && $1.c == 1 })

    do {
      let pre = Model()
      let new = Model()
      XCTAssertEqual(comparison(pre, new), false)
    }
    
    do {
      var pre = Model()
      pre.a = 1
      var new = Model()
      new.a = 1
      XCTAssertEqual(comparison(pre, new), true)
    }
    
    do {
      var pre = Model()
      pre.c = 1
      var new = Model()
      new.c = 1
      XCTAssertEqual(comparison(pre, new), true)
    }
    
  }
  
  func testCombinedFilterAnd() {
    
    struct Model {
      var a = 0
      var b = 0
      var c = 0
    }

    let comparison = AndComparator<Model, _, _>(
      .any { @Sendable in $0.a == 1 && $1.a == 1 },
      .any { @Sendable in  $0.b == 1 && $1.b == 1 }
    )
      .and(.any { @Sendable in $0.c == 1 && $1.c == 1 })

    do {
      let pre = Model()
      let new = Model()
      XCTAssertEqual(comparison(pre, new), false)
    }
    
    do {
      var pre = Model()
      pre.a = 1
      var new = Model()
      new.a = 1
      XCTAssertEqual(comparison(pre, new), false)
    }
    
    do {
      var pre = Model()
      pre.a = 1
      pre.b = 1
      var new = Model()
      new.a = 1
      new.b = 1
      XCTAssertEqual(comparison(pre, new), false)
    }
    
    do {
      var pre = Model()
      pre.a = 1
      pre.b = 1
      pre.c = 1
      var new = Model()
      new.a = 1
      new.b = 1
      new.c = 1
      XCTAssertEqual(comparison(pre, new), true)
    }
    
  }
}
