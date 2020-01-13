//
//  FilterTests.swift
//  VergeCoreTests
//
//  Created by muukii on 2020/01/14.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeCore

final class FilterTests: XCTestCase {
  
  func testHistorical() {
    
    let filter = Filters.Historical<Int>.init()
        
    XCTAssertEqual(filter.check(input: 1), true)
    XCTAssertEqual(filter.check(input: 1), false)
    XCTAssertEqual(filter.check(input: 2), true)
    
  }
  
  func testHistoricalWithFunction() {
    
    let filter = Filters.Historical<Int>.init().asFunction()
    
    XCTAssertEqual(filter(1), true)
    XCTAssertEqual(filter(1), false)
    XCTAssertEqual(filter(2), true)
    
  }
  
  func testHistoricalWithRegisterFirstValue() {
    
    let filter = Filters.Historical<Int>.init()
    
    filter.registerFirstValue(1)
    
    XCTAssertEqual(filter.check(input: 1), false)
    
  }
}
