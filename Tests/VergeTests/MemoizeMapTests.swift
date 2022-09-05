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

  func testEquatable() {

    XCTAssertEqual(
      Pipeline.map(\Changes<DemoState>.$nonEquatable), Pipeline.map(\Changes<DemoState>.$nonEquatable),
      """
      Using KeyPath, it could infer there is no involving outside state.
      Therefore, these are equivalent.
      It helps caching Derived objects.
      """
    )

    XCTAssertNotEqual(
      Pipeline.map({ (i: Changes<DemoStore.State>) in i.count }), Pipeline.map({ (i: Changes<DemoStore.State>) in i.count }),
      """
      Using closure, which means it can't infer that closure no contains outside variables.
      Therefore, these must be different.
      """
    )

  }

  func testEdge() {

    do {
      
      let result = Pipeline.map(\Changes<DemoState>.$nonEquatable)
      let erased = result as Any
      XCTAssertTrue(erased is Pipeline<Changes<DemoState>, Edge<NonEquatable>>)
    }

    do {
      let result = Pipeline.map(edge: \Changes<DemoState>.$nonEquatable)
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
      XCTAssertTrue(erased is Pipeline<Changes<DemoState>, Edge<OnEquatable>>)
    }

    do {
      let result = Pipeline.map(edge: \Changes<DemoState>.$onEquatable)
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
