//
//  InoutTests.swift
//  VergeCoreTests
//
//  Created by muukii on 2020/10/25.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest

@testable import VergeStore

fileprivate struct _COWBox<State> {

  private final class Storage {

    var value: State

    init(_ value: State) {
      self.value = value
    }

  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.storage === rhs.storage
  }

  private let onCopied: () -> Void

  init(wrappedValue: State, onCopied: @escaping () -> Void) {
    self.onCopied = onCopied
    self.storage = Storage(wrappedValue)
  }

  private var storage: Storage

  var wrappedValue: State {
    _read {
      yield storage.value
    }
    _modify {
      let oldValue = storage.value
      if isKnownUniquelyReferenced(&storage) {
        yield &storage.value
      } else {
        onCopied()
        storage = Storage(oldValue)
        yield &storage.value
      }
    }
  }

}

final class InoutTests: XCTestCase {

  func testOriginalBehavior() {

    var copied = false

    var value = _COWBox<Int>.init(wrappedValue: 0, onCopied: {
      copied = true
    })

    value.wrappedValue = 1

    XCTAssertEqual(value.wrappedValue, 1)
    XCTAssertEqual(copied, false)

    var value2 = value

    value2.wrappedValue = 0

    XCTAssertEqual(value.wrappedValue, 1)
    XCTAssertEqual(value2.wrappedValue, 0)
    XCTAssertEqual(copied, true)

  }

  func testOriginalBehavior2() {

    var copied = false

    var value = _COWBox<Int>.init(wrappedValue: 0, onCopied: {
      copied = true
    })

    func modify(_ v: _COWBox<Int>) -> _COWBox<Int> {
      var new = v
      new.wrappedValue = 0
      return new
    }

    value.wrappedValue = 1

    XCTAssertEqual(value.wrappedValue, 1)
    XCTAssertEqual(copied, false)

    value = modify(value)

    XCTAssertEqual(value.wrappedValue, 0)
    XCTAssertEqual(copied, true)

  }

  func testInout() {

    var copied = false

    var value = _COWBox<Int>.init(wrappedValue: 0, onCopied: {
      copied = true
    })

    withUnsafeMutablePointer(to: &value) { (pointer) -> Void in
      let proxy = InoutRef.init(pointer)

      proxy.wrappedValue = 1

      XCTAssertEqual(copied, false)
    }

    XCTAssertEqual(value.wrappedValue, 1)

  }

}

