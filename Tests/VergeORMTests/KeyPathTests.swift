//
//  KeyPathTests.swift
//  VergeORMTests
//
//  Created by muukii on 2020/10/13.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest

final class KeyPathTests: XCTestCase {

  struct Box<T> {
    let value: T
  }

  struct NoPropertyBox<T> {

  }

  struct OKModel {
    var name1: Box<String>
    var name2: Box<String>

  }

  struct NGModel {
    var name1: NoPropertyBox<String>
    var name2: NoPropertyBox<String>
  }

  func testKeyPath() {
    XCTAssertNotEqual(\OKModel.name1, \OKModel.name2)
    XCTAssertEqual(\NGModel.name1, \NGModel.name2)
  }


  func testKeyPathOnDB() {
    XCTAssertNotEqual(\RootState.db.indexes.allBooks, \RootState.db.indexes.bookMiddleware)
  }
}
