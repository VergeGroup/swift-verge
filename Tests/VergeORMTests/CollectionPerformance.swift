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
 
  func testArrayCast() {
    
    let a = (0..<10000).map { Int($0) }
    
    measure {
      _ = a as [Any]
    }
    
  }
  
  func testDictionaryCast() {
    
    let a = (0..<10000).reduce(into: [Int : Int]()) { (d, n) in
      d[n] = n
    }
    
    measure {
      _ = a as [Int : Any]
    }
    
  }
    
  func testDictionaryCastFromAny() {
    
    let a = (0..<10000).reduce(into: [Int : Any]()) { (d, n) in
      d[n] = n
    }
    
    measure {
      _ = a as! [Int : Int]
    }
    
  }
}
