//
//  UtilTests.swift
//  VergeORMTests
//
//  Created by muukii on 2020/04/29.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation
import XCTest

class UtilTests: XCTestCase {
  
  func testObjectIdentifier() {
        
    struct A {
      
      struct B {
        
        struct A {
          
        }
      }
    }
    
    
    let a = ObjectIdentifier(A.self)
    let b = ObjectIdentifier(A.B.A.self)
    
    XCTAssertNotEqual(a, b)
        
  }
}
