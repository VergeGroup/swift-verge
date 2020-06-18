//
//  DateTests.swift
//  VergeCore
//
//  Created by muukii on 2020/01/13.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeStore

final class CounterTests: XCTestCase {
    
  func testCounter() {
    
    var counter = NonAtomicVersionCounter()
    
    for _ in 0..<100 {
      
      counter.markAsUpdated()
    }
    
    XCTAssertEqual(counter.version, 100)
  }
  
  func testCounterPerformance() {
    var counter = NonAtomicVersionCounter()
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
