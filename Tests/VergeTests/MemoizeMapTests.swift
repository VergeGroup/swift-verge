//
//  MemoizeMapTests.swift
//  VergeTests
//
//  Created by muukii on 2020/12/01.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation
import XCTest

import Verge

final class MemoizeMapTests: XCTestCase {
 
  func testEdge() {

    do {
      
      let result = Pipeline.map(\Changes<DemoState>.$nonEquatable)
      let erased = result as Any
      XCTAssertTrue(erased is Pipeline<Changes<DemoState>, NonEquatable>)
    }

    do {
      let result = Pipeline.map(\Changes<DemoState>.$nonEquatable)
      let erased = result as Any
      XCTAssertTrue(erased is Pipeline<Changes<DemoState>, NonEquatable>)
    }

    do {
      let result = Pipeline.map(\Changes<DemoState>.nonEquatable)
      let erased = result as Any
      XCTAssertTrue(erased is Pipeline<Changes<DemoState>, NonEquatable>)
    }

    do {
      let result = Pipeline.map(\Changes<DemoState>.$onEquatable)
      let erased = result as Any
      XCTAssertTrue(erased is Pipeline<Changes<DemoState>, OnEquatable>)
    }

    do {
      let result = Pipeline.map(\Changes<DemoState>.$onEquatable)
      let erased = result as Any
      XCTAssertTrue(erased is Pipeline<Changes<DemoState>, OnEquatable>)
    }

    do {
      let result = Pipeline.map(\Changes<DemoState>.onEquatable)
      let erased = result as Any
      XCTAssertTrue(erased is Pipeline<Changes<DemoState>, OnEquatable>)
    }

  }

}
