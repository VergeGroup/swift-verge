//
//  CollectionPerformance.swift
//  VergeORM
//
//  Created by muukii on 2019/12/21.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import XCTest

class CollectionPerformance: XCTestCase {  
  
  func testMakeCollection() {
    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      _ = AnyCollection((0..<100000).map { $0 })
    }
  }
  
  func testMakeLazySequence() {
    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      _ = (0..<100000).lazy.map { $0 }
    }
  }
  
  func testMakeLazyCollection() {
    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      _ = AnyCollection((0..<100000).lazy.map { $0 })
    }
  }
  
  func testArrayCast() {
    
    let a = (0..<10000).map { Int($0) }
    
    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      _ = a as [Any]
    }
    
  }
  
  func testDictionaryCast() {
    
    let a = (0..<10000).reduce(into: [Int : Int]()) { (d, n) in
      d[n] = n
    }
    
    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      _ = a as [Int : Any]
    }
    
  }
    
  func testDictionaryCastFromAny() {
    
    let a = (0..<10000).reduce(into: [Int : Any]()) { (d, n) in
      d[n] = n
    }
    
    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      _ = a as! [Int : Int]
    }
    
  }
  
  func testLoop() {
         
  }
}
