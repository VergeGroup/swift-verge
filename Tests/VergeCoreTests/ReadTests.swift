//
//  ReadTests.swift
//  VergeCore
//
//  Created by muukii on 2020/10/25.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeCore

final class ReadTests: XCTestCase {

  func testBasic() {

    let demoState = DemoState()

    let read = UnsafeReadReference.init(demoState)

    XCTAssertEqual(read.count, 0)

  }
  
}
