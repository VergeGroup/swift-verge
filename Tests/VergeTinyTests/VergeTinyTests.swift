//
// Copyright (c) 2021 Hiroshi Kimura(Muukii) <muukii.app@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import VergeTiny
import XCTest

final class VergeTinyTests: XCTestCase {

  func testDefineProperty() {

    let filter = DynamicPropertyStorage()

    let property = filter.defineProperty(Int.self)

    XCTAssertEqual(property.value, nil)

    property.value = 1

    XCTAssertEqual(property.value, 1)
  }

  func testDistinct() {

    let filter = DynamicPropertyStorage()

    let property = filter.defineProperty(Int.self)

    let exp = expectation(description: "")
    exp.assertForOverFulfill = true
    exp.expectedFulfillmentCount = 2

    property.doIfChanged(1) { value in
      XCTAssertEqual(value, 1)
      exp.fulfill()
    }

    property.doIfChanged(1) { value in
      XCTFail()
    }

    property.doIfChanged(2) { value in
      XCTAssertEqual(value, 2)
      exp.fulfill()
    }

    wait(for: [exp], timeout: 0)
  }

  func testDistinctOptional() {

    let filter = DynamicPropertyStorage()

    let property = filter.defineProperty(Int?.self)

    let exp = expectation(description: "")
    exp.assertForOverFulfill = true
    exp.expectedFulfillmentCount = 4

    property.doIfChanged(nil) { value in
      XCTAssertEqual(value, nil)
      exp.fulfill()
    }

    property.doIfChanged(nil) { value in
      XCTFail()
    }

    property.doIfChanged(1) { value in
      XCTAssertEqual(value, 1)
      exp.fulfill()
    }

    property.doIfChanged(1) { value in
      XCTFail()
    }

    property.doIfChanged(2) { value in
      XCTAssertEqual(value, 2)
      exp.fulfill()
    }

    property.doIfChanged(nil) { value in
      XCTAssertEqual(value, nil)
      exp.fulfill()
    }

    property.doIfChanged(nil) { value in
      XCTFail()
    }

    wait(for: [exp], timeout: 0)
  }

  func testPerformanceCreatingProperty() {

    let filter = DynamicPropertyStorage()
    measure {
      let _ = filter.defineProperty(Int?.self)
    }
  }

  func testPerformanceAccessingProperty() {

    let filter = DynamicPropertyStorage()
    let property = filter.defineProperty(Int.self)
    property.value = 1
    measure {
      property.value? += 1
    }
  }
}
