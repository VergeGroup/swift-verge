//
//  KeyPathIdentifierStoreTests.swift
//  VergeTests
//
//  Created by Muukii on 2021/01/02.
//  Copyright © 2021 muukii. All rights reserved.
//

import Foundation

import Foundation
import XCTest

@testable import Verge

final class KeyPathIdentifierStoreTests: XCTestCase {

  func test() {

    do {

      let a: AnyKeyPath = \DemoState.count
      let b: AnyKeyPath = \DemoState.count

      /**
       In Playground, I found a case of created in different pointer by same key-path.
       */
      XCTAssert(a === b)

      XCTAssertEqual(
        KeyPathIdentifierStore.getLocalIdentifier(a),
        KeyPathIdentifierStore.getLocalIdentifier(b)
      )

    }

    do {

      let a: AnyKeyPath = \DemoState.count
      let b: AnyKeyPath = \DemoState.inner

      /**
       In Playground, I found a case of created in different pointer by same key-path.
       */
      XCTAssert(a !== b)

      XCTAssertNotEqual(
        KeyPathIdentifierStore.getLocalIdentifier(a),
        KeyPathIdentifierStore.getLocalIdentifier(b)
      )

    }

  }

  func testPerformanceInSerial() {

    measure {
      for _ in 0..<200 {
        XCTAssertEqual(
          KeyPathIdentifierStore.getLocalIdentifier(\DemoState.count),
          KeyPathIdentifierStore.getLocalIdentifier(\DemoState.count)
        )
      }
    }

  }

  func testPerformanceInConcurrent() {

    measure {
      DispatchQueue.concurrentPerform(iterations: 200) { _ in
        XCTAssertEqual(
        KeyPathIdentifierStore.getLocalIdentifier(\DemoState.count),
        KeyPathIdentifierStore.getLocalIdentifier(\DemoState.count)
        )
      }
    }

  }
}
