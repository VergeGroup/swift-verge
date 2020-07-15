//
//  ReflectingTests.swift
//  VergeORMTests
//
//  Created by muukii on 2020/05/05.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation
import XCTest

class ReflectingTests: XCTestCase {
  
  struct A {
    struct B {
      struct A {
      }
    }
  }
  
  func testGettingTypeName_typeof() {
    
    measure {
      for _ in 0..<10000 {
        _ = type(of: A.B.A.self)
      }
    }
  }
  
  func testGettingTypeName_typeName_metatype() {
    
    measure {
      for _ in 0..<10000 {
        _ = _typeName(type(of: A.B.A.self))
      }
    }
  }
  
  func testGettingTypeName_string_reflecting_metatype() {
    
    measure {
      for _ in 0..<10000 {
        _ = String(reflecting: type(of: A.B.A.self))
      }
    }
  }
  
  func testGettingTypeName_string_reflecting() {
    
    measure {
      for _ in 0..<10000 {
        _ = String(reflecting: A.B.A.self)
      }
    }
  }

  func testObjectIdentifier_string_reflecting() {

    measure {
      for _ in 0..<10000 {
        _ = ObjectIdentifier(A.B.A.self)
      }
    }
  }
}
