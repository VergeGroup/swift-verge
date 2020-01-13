//
//  DateTests.swift
//  VergeCore
//
//  Created by muukii on 2020/01/13.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeCore

final class CounterTests: XCTestCase {
    
  func testCounter() {
    
    var counter = UpdatedMarker()
    
    for _ in 0..<100 {
      
      counter.markAsUpdated()
    }
    
    XCTAssertEqual(counter.rawValue, 100)
  }
  
  func testCounterPerformance() {
    var counter = UpdatedMarker()
    if #available(iOS 13.0, *) {
      measure(metrics: [XCTCPUMetric()]) {
        counter.markAsUpdated()
      }
    } else {
      // Fallback on earlier versions
    }
  }
  
  func testGenDatePerformance() {
    
    measure {
      _ = Date()
    }
  }
  
  func testGenCFDatePerformance() {
    
    measure {
      _ = CFAbsoluteTimeGetCurrent()
    }
  }
}
