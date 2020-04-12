//
//  FilterTests.swift
//  VergeCoreTests
//
//  Created by muukii on 2020/01/14.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeStore

final class FilterTests: XCTestCase {
  
  func testHistorical() {
    
    let filter = EqualityComputer<Int>.init(selector: { $0 }, comparer: .init { $0 == $1 })
        
    XCTAssertEqual(filter.equals(input: 1), false)
    XCTAssertEqual(filter.equals(input: 1), true)
    XCTAssertEqual(filter.equals(input: 2), false)
    
  }
  
  func testHistoricalWithFunction() {
    
    let filter = EqualityComputer<Int>.init(selector: { $0 }, comparer: .init { $0 == $1 }).asFunction()
    
    XCTAssertEqual(filter(1), false)
    XCTAssertEqual(filter(1), true)
    XCTAssertEqual(filter(2), false)
    
  }
  
  func testHistoricalWithRegisterFirstValue() {
    
    let filter = EqualityComputer<Int>.init(selector: { $0 }, comparer: .init { $0 == $1 })
    
    filter.registerFirstValue(1)
    
    XCTAssertEqual(filter.equals(input: 1), true)
    
  }
  
  func testCombinedFilterOR() {
    
    struct Model {
      var a = 0
      var b = 0
      var c = 0
    }
        
    let fragment = Comparer<Model>.init(or: [
      Comparer<Model>.init { $0.a == 1 && $1.a == 1 },
      Comparer<Model>.init { $0.b == 1 && $1.b == 1 },
      Comparer<Model>.init { $0.c == 1 && $1.c == 1 },
    ])
        
    do {
      let pre = Model()
      let new = Model()
      XCTAssertEqual(fragment.equals(pre, new), false)
    }
    
    do {
      var pre = Model()
      pre.a = 1
      var new = Model()
      new.a = 1
      XCTAssertEqual(fragment.equals(pre, new), true)
    }
    
    do {
      var pre = Model()
      pre.c = 1
      var new = Model()
      new.c = 1
      XCTAssertEqual(fragment.equals(pre, new), true)
    }
    
  }
  
  func testCombinedFilterAnd() {
    
    struct Model {
      var a = 0
      var b = 0
      var c = 0
    }
    
    let fragment = Comparer<Model>.init(and: [
      Comparer<Model>.init { $0.a == 1 && $1.a == 1 },
      Comparer<Model>.init { $0.b == 1 && $1.b == 1 },
      Comparer<Model>.init { $0.c == 1 && $1.c == 1 },
    ])
    
    do {
      let pre = Model()
      let new = Model()
      XCTAssertEqual(fragment.equals(pre, new), false)
    }
    
    do {
      var pre = Model()
      pre.a = 1
      var new = Model()
      new.a = 1
      XCTAssertEqual(fragment.equals(pre, new), false)
    }
    
    do {
      var pre = Model()
      pre.a = 1
      pre.b = 1
      var new = Model()
      new.a = 1
      new.b = 1
      XCTAssertEqual(fragment.equals(pre, new), false)
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
      XCTAssertEqual(fragment.equals(pre, new), true)
    }
    
  }
}
