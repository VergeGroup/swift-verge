//
//  StoreSliceTests.swift
//  VergeStore
//
//  Created by muukii on 2020/04/21.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation
import XCTest

import Verge

private protocol MyProtocol {
  
}

private protocol MyEquatableProtocol: Equatable {
  
}

final class DerivedTests: XCTestCase {

  func testSlice() {

    let localStore = DemoStore()
                    
    let slice = localStore.derived(.map({ $0.count }), queue: .passthrough)      

    XCTAssertEqual(slice.primitiveValue, 0)
    XCTAssertEqual(slice.state.root, 0)
    XCTAssertEqual(slice.state.hasChanges(\.self), true)
    
    localStore.increment()

    XCTAssertEqual(slice.primitiveValue, 1)
    XCTAssertEqual(slice.state.root, 1)
    XCTAssertEqual(slice.state.hasChanges(\.self), true)
      
    localStore.empty()

    XCTAssertEqual(slice.primitiveValue, 1)
    XCTAssertEqual(slice.state.version, 1)
    XCTAssertEqual(slice.state.hasChanges(\.self), true)

    localStore.empty()

    XCTAssertEqual(slice.primitiveValue, 1)
    XCTAssertEqual(slice.state.version, 1)
    XCTAssertEqual(slice.state.hasChanges(\.self), true)

    localStore.increment()

    XCTAssertEqual(slice.primitiveValue, 2)
    XCTAssertEqual(slice.state.version, 2)
    XCTAssertEqual(slice.state.hasChanges(\.self), true)
  }

  func testSlice2() {

    let wrapper = DemoStore()

    let slice = wrapper.derived(
      .map { $0.count }.drop { $0.noChanges(\.self) },
      queue: .passthrough
    )

    XCTAssertEqual(slice.primitiveValue, 0)
    XCTAssertEqual(slice.state.root, 0)
    XCTAssertEqual(slice.state.hasChanges(\.self), true)

    wrapper.increment()

    XCTAssertEqual(slice.primitiveValue, 1)
    XCTAssertEqual(slice.state.root, 1)
    XCTAssertEqual(slice.state.hasChanges(\.self), true)

    wrapper.empty()

    XCTAssertEqual(slice.primitiveValue, 1)
    XCTAssertEqual(slice.state.version, 1)
    XCTAssertEqual(slice.state.hasChanges(\.self), true)

    wrapper.empty()

    XCTAssertEqual(slice.primitiveValue, 1)
    XCTAssertEqual(slice.state.version, 1)
    XCTAssertEqual(slice.state.hasChanges(\.self), true)

    wrapper.increment()

    XCTAssertEqual(slice.primitiveValue, 2)
    XCTAssertEqual(slice.state.version, 2)
    XCTAssertEqual(slice.state.hasChanges(\.self), true)
  }
    
  /// combine 2 stored
  func testCombine2() {

    let wrapper = DemoStore()
    
    let s0 = wrapper.derived(.map { $0.count }, queue: .passthrough)
    let s1 = wrapper.derived(.map { $0.name }, queue: .passthrough)
    
    let updateCount = expectation(description: "updatecount")
    updateCount.assertForOverFulfill = true
    updateCount.expectedFulfillmentCount = 3
    
    let update0 = expectation(description: "")
    update0.assertForOverFulfill = true
    update0.expectedFulfillmentCount = 2
    
    let update1 = expectation(description: "")
    update1.assertForOverFulfill = true
    update1.expectedFulfillmentCount = 2
        
    let combined = Derived.combined(s0, s1, queue: .passthrough)
    
    XCTAssert((combined.primitiveValue.0.primitive, combined.primitiveValue.1.primitive) == (0, ""))
        
    let sub = combined.sinkState { (changes) in
      
      updateCount.fulfill()
      
      changes.ifChanged(\.0) { _0 in
        update0.fulfill()
      }
      
      changes.ifChanged(\.1) { _1 in
        update1.fulfill()
      }
      
    }
    
    wrapper.commit {
      $0.count += 1
    }
    
    XCTAssert((combined.primitiveValue.0.primitive, combined.primitiveValue.1.primitive) == (1, ""))
    
    wrapper.commit {
      $0.name = "next"
    }
    
    XCTAssert((combined.primitiveValue.0.primitive, combined.primitiveValue.1.primitive) == (1, "next"))
    
    wait(for: [updateCount, update1, update0], timeout: 10)
    withExtendedLifetime(sub) {}
  }
          
}

final class DerivedCacheTests: XCTestCase {
  
  func test_identify_keypath() {
    
    let store1 = DemoStore()
    let store2 = DemoStore()
    
    XCTAssert(store1.derived(.map(\.count)) !== store1.derived(.map(\.count)))
    
    /// Stored in each store
    XCTAssert(store1.derived(.map(\.count)) !== store2.derived(.map(\.count)))
    
  }
  
  func test_identify_keypath_specify_queue_main() {
    
    let store1 = DemoStore()
    let store2 = DemoStore()

    XCTAssert(
      store1.derived(.map(\.count), queue: .asyncMain) !==
        store1.derived(.map(\.count), queue: .asyncMain)
    )
    
    XCTAssert(
      store1.derived(.map(\.count), queue: .main) !==
        store1.derived(.map(\.count), queue: .main)
    )

    XCTAssert(
      store1.derived(.map(\.count)) !==
        store1.derived(.map(\.count), queue: .main)
    )

    XCTAssert(
      store1.derived(.map(\.count)) !==
        store2.derived(.map(\.count))
    )
    
  }
  
  func test_identify_keypath_specify_queue_any() {
    
    let store1 = DemoStore()
    let store2 = DemoStore()
    
    let queue = AnyTargetQueue.specific(DispatchQueue(label: "test"))
    let queue2 = AnyTargetQueue.specific(DispatchQueue(label: "test"))
    
    XCTAssert(store1.derived(.map(\.count), queue: queue) !== store1.derived(.map(\.count), queue: queue))
    XCTAssert(store1.derived(.map(\.count), queue: queue) !== store1.derived(.map(\.count), queue: .main))
    XCTAssert(store1.derived(.map(\.count), queue: queue) !== store1.derived(.map(\.count), queue: queue2))
    XCTAssert(store1.derived(.map(\.count)) !== store2.derived(.map(\.count)))
        
  }
  
  func test_identify_keypath_specify_queue_global() {
    
    let store1 = DemoStore()
    let store2 = DemoStore()
    
    let queue = AnyTargetQueue.specific(DispatchQueue.global())
    
    XCTAssert(store1.derived(.map(\.count), queue: queue) !== store1.derived(.map(\.count), queue: queue))
    XCTAssert(store1.derived(.map(\.count), queue: queue) !== store1.derived(.map(\.count), queue: .main))
    XCTAssert(store1.derived(.map(\.count)) !== store2.derived(.map(\.count)))
    
  }
     
}
