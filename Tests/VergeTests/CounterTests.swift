//
//  DateTests.swift
//  VergeCore
//
//  Created by muukii on 2020/01/13.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest

import Verge

final class CounterTests: XCTestCase {
    
  func testCounter() {
    
    var counter = NonAtomicCounter()
    
    for _ in 0..<100 {
      
      counter.increment()
    }
    
    XCTAssertEqual(counter.value, 100)
  }
  
  func testCounterPerformance() {
    var counter = NonAtomicCounter()
    if #available(iOS 13.0, *) {
      measure(metrics: [XCTCPUMetric()]) {
        counter.increment()
      }
    } else {
      // Fallback on earlier versions
    }
  }
  
  func testGenDatePerformance() {
    
    vergeMeasure {
      _ = Date()
    }
  }
  
  func testGenCFDatePerformance() {
    
    vergeMeasure {
      _ = CFAbsoluteTimeGetCurrent()
    }
  }
}
