//
//  InoutTests.swift
//  VergeCoreTests
//
//  Created by muukii on 2020/10/25.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest

import Verge

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

  func testRef() {

    var state = DemoState()

    withUnsafeMutablePointer(to: &state) { pointer in

      let ref1 = InoutRef(pointer)
      let ref2 = InoutRef(pointer)

      XCTAssertEqual(ref1.count, ref2.count)

      ref1.count = 100

      XCTAssertEqual(ref1.count, 100)
      XCTAssertEqual(ref1.count, ref2.count)

      ref1.map(keyPath: \.inner) { i in
        i.name = "Hi"
      }

      XCTAssertEqual(ref1.inner.name, "Hi")
      XCTAssertEqual(ref1.inner.name, ref2.inner.name)

    }

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

  func testModification_NoModified() {

    var value = DemoState()

    let modification = withUnsafeMutablePointer(to: &value) { (pointer) -> InoutRef<DemoState>.Modification? in
      let proxy = InoutRef.init(pointer)
      return proxy.modification
    }

    switch modification {
    case .indeterminate?:
      XCTFail()
    case .determinate?:
      XCTFail()
    case .none:
      break
    }

  }

  func testModification() {

    var value = DemoState()

    let modification = withUnsafeMutablePointer(to: &value) { (pointer) -> InoutRef<DemoState>.Modification? in
      let proxy = InoutRef.init(pointer)
      proxy.count += 1
      
      XCTAssert(proxy.hasModified(\.self))
      XCTAssert(proxy.hasModified(\DemoState.count))
      
      return proxy.modification
    }

    switch modification {
    case .indeterminate?:
      XCTFail()
    case .determinate(let keyPaths)?:
      XCTAssert(keyPaths.contains(\DemoState.count))
    case .none:
      XCTFail()
    }

  }

  func testModification_Map() {

    var value = DemoState()

    let modification = withUnsafeMutablePointer(to: &value) { (pointer) -> InoutRef<DemoState>.Modification? in
      let proxy = InoutRef.init(pointer)
      proxy.count += 1
      proxy.map(keyPath: \.inner) { (inner) in
        inner.name = UUID().uuidString
      }
      return proxy.modification
    }

    switch modification {
    case .indeterminate?:
      XCTFail()
    case .determinate(let keyPaths)?:
      XCTAssert(keyPaths.contains(\DemoState.count))
      XCTAssert(keyPaths.contains(\DemoState.inner.name))
    case .none:
      XCTFail()
    }

  }

  func testModification_indeterminate_modify() {

    var value = DemoState()

    let modification = withUnsafeMutablePointer(to: &value) { (pointer) -> InoutRef<DemoState>.Modification? in
      let proxy = InoutRef.init(pointer)
      proxy.modify {
        $0.count += 1
      }
      return proxy.modification
    }

    switch modification {
    case .indeterminate?:
      break
    case .determinate?:
      XCTFail()
    case .none:
      XCTFail()
    }

  }
  
  func testModification_dynamicMemberLookup() {
    
    var value = DemoState()
    
    let modification = withUnsafeMutablePointer(to: &value) { (pointer) -> InoutRef<DemoState>.Modification? in
      let proxy = InoutRef.init(pointer)
      proxy.modify {
        $0.count += 1
      }
      return proxy.modification
    }
    
    XCTAssertEqual(modification?.count, true)
  }

  func testModification_modifying_wrapped_directly() {

    var value = DemoState()

    let modification = withUnsafeMutablePointer(to: &value) { (pointer) -> InoutRef<DemoState>.Modification? in
      let proxy = InoutRef.init(pointer)
      proxy.wrapped.updateFromItself()
      return proxy.modification
    }

    switch modification {
    case .indeterminate?:
      break
    case .determinate?:
      XCTFail()
    case .none:
      XCTFail()
    }

  }

}

#if false
final class ReadRefTests: XCTestCase {

  func testRef() {

    var state = DemoState()

    withUnsafePointer(to: state) { (pointer) in
      let ref = ReadRef(pointer)
      state.count = 100
      XCTAssertEqual(ref.count, state.count)
    }

  }

}
#endif
