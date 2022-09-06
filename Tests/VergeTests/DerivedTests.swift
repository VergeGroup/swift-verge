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

final class DerivedTests: XCTestCase {

  func testSlice() {

    let localStore = DemoStore()
                
    let slice = localStore.derived(.map { $0.count }, queue: .passthrough)

    XCTAssertEqual(slice.primitiveValue, 0)
    XCTAssertEqual(slice.value.root, 0)
    XCTAssertEqual(slice.value.hasChanges(\.root), true)
    
    localStore.increment()

    XCTAssertEqual(slice.primitiveValue, 1)
    XCTAssertEqual(slice.value.root, 1)
    XCTAssertEqual(slice.value.hasChanges(\.root), true)
      
    localStore.empty()

    XCTAssertEqual(slice.primitiveValue, 1)
    XCTAssertEqual(slice.value.version, 1)
    XCTAssertEqual(slice.value.hasChanges(\.root), true)

    localStore.empty()

    XCTAssertEqual(slice.primitiveValue, 1)
    XCTAssertEqual(slice.value.version, 1)
    XCTAssertEqual(slice.value.hasChanges(\.root), true)

    localStore.increment()

    XCTAssertEqual(slice.primitiveValue, 2)
    XCTAssertEqual(slice.value.version, 2)
    XCTAssertEqual(slice.value.hasChanges(\.root), true)
  }

  func testSlice2() {

    let wrapper = DemoStore()

    let slice = wrapper.derived(
      .map { $0.count }.drop { $0.noChanges(\.root) },
      queue: .passthrough
    )

    XCTAssertEqual(slice.primitiveValue, 0)
    XCTAssertEqual(slice.value.root, 0)
    XCTAssertEqual(slice.value.hasChanges(\.root), true)

    wrapper.increment()

    XCTAssertEqual(slice.primitiveValue, 1)
    XCTAssertEqual(slice.value.root, 1)
    XCTAssertEqual(slice.value.hasChanges(\.root), true)

    wrapper.empty()

    XCTAssertEqual(slice.primitiveValue, 1)
    XCTAssertEqual(slice.value.version, 1)
    XCTAssertEqual(slice.value.hasChanges(\.root), true)

    wrapper.empty()

    XCTAssertEqual(slice.primitiveValue, 1)
    XCTAssertEqual(slice.value.version, 1)
    XCTAssertEqual(slice.value.hasChanges(\.root), true)

    wrapper.increment()

    XCTAssertEqual(slice.primitiveValue, 2)
    XCTAssertEqual(slice.value.version, 2)
    XCTAssertEqual(slice.value.hasChanges(\.root), true)
  }

  func testBinding() {

    let wrapper = DemoStore()
    
    let slice = wrapper.bindingDerived(
      get: .map { $0.count },
      set: { source, new in
        source.count = new
    })
    
    slice.primitiveValue = 2
        
    XCTAssertEqual(wrapper.primitiveState.count, 2)
    
  }
  
  func testRetain() {

    let wrapper = DemoStore()
    
    var baseSlice: Derived<Int>! = wrapper.derived(.map { $0.count }, queue: .passthrough)
    weak var weakBaseSlice = baseSlice
    
    let expectation = XCTestExpectation(description: "receive changes")
    expectation.expectedFulfillmentCount = 1
    expectation.assertForOverFulfill = true
    
    let subscription = baseSlice.sinkValue(dropsFirst: true, queue: .passthrough) { (changes) in
      expectation.fulfill()
    }

    XCTAssertNotNil(weakBaseSlice)
    // deinit
    baseSlice = nil
    
    XCTAssertNotNil(weakBaseSlice, "it won't be deinitiallized")
    
    wrapper.commit { _ in }
        
    wrapper.commit { $0.count += 1 }
            
    subscription.cancel()
    
    XCTAssertNil(weakBaseSlice)
    
    wait(for: [expectation], timeout: 1)
    
  }
  
  func testSliceChain() {

    let wrapper = DemoStore()
    
    var baseSlice: Derived<Int>! = wrapper.derived(.map { $0.count }, queue: .passthrough)
    
    weak var weakBaseSlice = baseSlice
            
    var slice: Derived<Int>! = baseSlice.chain(.map { $0.root }, queue: .passthrough)
    
    baseSlice = nil
    
    weak var weakSlice = slice
        
    XCTAssertEqual(slice.primitiveValue, 0)
    XCTAssertEqual(slice.value.version, 0)
    XCTAssertEqual(slice.value.hasChanges(\.root), true)
    XCTAssertNotNil(weakBaseSlice)
    
    wrapper.increment()
        
    XCTAssertEqual(slice.primitiveValue, 1)
    XCTAssertEqual(slice.value.version, 1)
    XCTAssertEqual(slice.value.hasChanges(\.root), true)
    XCTAssertNotNil(weakBaseSlice)
    
    wrapper.empty()
    
    XCTAssertEqual(slice.primitiveValue, 1)
    XCTAssertEqual(slice.value.version, 1) // with memoized, version not changed
    XCTAssertEqual(slice.value.hasChanges(\.root), true)
    XCTAssertNotNil(weakBaseSlice)
    
    wrapper.increment()
    
    XCTAssertEqual(slice.primitiveValue, 2)
    XCTAssertEqual(slice.value.version, 2)
    XCTAssertEqual(slice.value.hasChanges(\.root), true)
    XCTAssertNotNil(weakBaseSlice)

    slice = nil
       
    XCTAssertNil(weakSlice)
    XCTAssertNil(weakBaseSlice)

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
        
    let d = Derived.combined(s0, s1, queue: .passthrough)
    
    XCTAssert(d.primitiveValue == (0, ""))
        
    let sub = d.sinkValue { (changes) in
      
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
    
    XCTAssert(d.primitiveValue == (1, ""))
    
    wrapper.commit {
      $0.name = "next"
    }
    
    XCTAssert(d.primitiveValue == (1, "next"))
    
    wait(for: [updateCount, update1, update0], timeout: 10)
    withExtendedLifetime(sub) {}
  }
    
  /// combine 1 Stored and 1 Computed
  func testCombine2computed() {

    let wrapper = DemoStore()
    
    let s0 = wrapper.derived(.map { $0.count }, queue: .passthrough)
    let s1 = wrapper.derived(.map { $0.computed.nameCount }, queue: .passthrough)
    
    let updateCount = expectation(description: "updatecount")
    updateCount.assertForOverFulfill = true
    updateCount.expectedFulfillmentCount = 3
    
    let update0 = expectation(description: "")
    update0.assertForOverFulfill = true
    update0.expectedFulfillmentCount = 2
    
    let update1 = expectation(description: "")
    update1.assertForOverFulfill = true
    update1.expectedFulfillmentCount = 2
    
    let d = Derived.combined(s0, s1, queue: .passthrough)
    
    XCTAssert(d.primitiveValue == (0, 0))
    
    let sub = d.sinkValue { (changes) in
      
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
    
    XCTAssert(d.primitiveValue == (1, 0))
    
    wrapper.commit {
      $0.name = "next"
    }
    
    XCTAssert(d.primitiveValue == (1, 4))
    
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
    
    let queue = TargetQueue.specific(DispatchQueue(label: "test"))
    let queue2 = TargetQueue.specific(DispatchQueue(label: "test"))
    
    XCTAssert(store1.derived(.map(\.count), queue: queue) !== store1.derived(.map(\.count), queue: queue))
    XCTAssert(store1.derived(.map(\.count), queue: queue) !== store1.derived(.map(\.count), queue: .main))
    XCTAssert(store1.derived(.map(\.count), queue: queue) !== store1.derived(.map(\.count), queue: queue2))
    XCTAssert(store1.derived(.map(\.count)) !== store2.derived(.map(\.count)))
        
  }
  
  func test_identify_keypath_specify_queue_global() {
    
    let store1 = DemoStore()
    let store2 = DemoStore()
    
    let queue = TargetQueue.specific(DispatchQueue.global())
    
    XCTAssert(store1.derived(.map(\.count), queue: queue) !== store1.derived(.map(\.count), queue: queue))
    XCTAssert(store1.derived(.map(\.count), queue: queue) !== store1.derived(.map(\.count), queue: .main))
    XCTAssert(store1.derived(.map(\.count)) !== store2.derived(.map(\.count)))
    
  }
  
  func test_identify_by_instance() {
    
    let store1 = DemoStore()
    
    XCTAssert(store1.derived(.map { $0.count }) !== store1.derived(.map { $0.count }))
   
    let map = Pipeline<Changes<DemoState>, Int>.map { $0.count }
    
    XCTAssert(store1.derived(map) !== store1.derived(map))

  }
  
}
