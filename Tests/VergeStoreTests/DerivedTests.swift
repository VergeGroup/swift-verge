//
//  StoreSliceTests.swift
//  VergeStore
//
//  Created by muukii on 2020/04/21.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation
import XCTest

import VergeStore

final class DerivedTests: XCTestCase {
  
  final class StoreWrapper: StoreWrapperType {
    
    struct State {
      var count = 0
    }
    
    enum Activity {}
    
    let store = DefaultStore.init(initialState: .init(), logger: nil)
    
    func increment() {
      commit {
        $0.count += 1
      }
    }
    
    func empty() {
      commit { _ in
      }
    }
  }
  
  let wrapper = StoreWrapper()
  
  func testSlice() {
                
    let slice = wrapper.derived(.map { $0.count })
    
    XCTAssertEqual(slice.state, 0)
    XCTAssertEqual(slice.changes.hasChanges(\.root), true)
    
    wrapper.increment()
    
    XCTAssertEqual(slice.state, 1)
    XCTAssertEqual(slice.changes.hasChanges(\.root), true)
      
    wrapper.empty()
    
    XCTAssertEqual(slice.state, 1)
    XCTAssertEqual(slice.changes.hasChanges(\.root), false)
  }
  
  func testBinding() {
    
    let slice = wrapper.binding(
      get: .map { $0.count },
      set: { source, new in
        source.count = new
    })
    
    slice.state = 2
        
    XCTAssertEqual(wrapper.state.count, 2)
    
  }
  
  func testRetain() {
    
    var baseSlice: Derived<Int>! = wrapper.derived(.map { $0.count })
    weak var weakBaseSlice = baseSlice
    
    let expectation = XCTestExpectation(description: "receive changes")
    expectation.expectedFulfillmentCount = 1
    expectation.assertForOverFulfill = true
    
    let subscription = baseSlice.subscribeStateChanges(dropsFirst: true) { (changes) in
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
    
    var baseSlice: Derived<Int>! = wrapper.derived(.map { $0.count })
    
    weak var weakBaseSlice = baseSlice
            
    var slice: Derived<Int>! = baseSlice.chain(.map { $0.current })
    
    baseSlice = nil
    
    weak var weakSlice = slice
        
    XCTAssertEqual(slice.state, 0)
    XCTAssertEqual(slice.changes.version, 0)
    XCTAssertEqual(slice.changes.hasChanges(\.root), true)
    XCTAssertNotNil(weakBaseSlice)
    
    wrapper.increment()
        
    XCTAssertEqual(slice.state, 1)
    XCTAssertEqual(slice.changes.version, 1)
    XCTAssertEqual(slice.changes.hasChanges(\.root), true)
    XCTAssertNotNil(weakBaseSlice)
    
    wrapper.empty()
    
    XCTAssertEqual(slice.state, 1)
    XCTAssertEqual(slice.changes.version, 1) // with memoized, version not changed
    XCTAssertEqual(slice.changes.hasChanges(\.root), true)
    XCTAssertNotNil(weakBaseSlice)
    
    wrapper.increment()
    
    XCTAssertEqual(slice.state, 2)
    XCTAssertEqual(slice.changes.version, 2)
    XCTAssertEqual(slice.changes.hasChanges(\.root), true)
    XCTAssertNotNil(weakBaseSlice)

    slice = nil
       
    XCTAssertNil(weakSlice)
    XCTAssertNil(weakBaseSlice)

  }
  
}
