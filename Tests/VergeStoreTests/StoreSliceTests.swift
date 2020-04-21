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

final class StoreSliceTests: XCTestCase {
  
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
        
    let slice = wrapper.slice { (changes) in
      changes.count
    }
    
    XCTAssertEqual(slice.state, 0)
    XCTAssertEqual(slice.changes.hasChanges(\.self), true)
    
    wrapper.increment()
    
    XCTAssertEqual(slice.state, 1)
    XCTAssertEqual(slice.changes.hasChanges(\.self), true)
      
    wrapper.empty()
    
    XCTAssertEqual(slice.state, 1)
    XCTAssertEqual(slice.changes.hasChanges(\.self), false)
  }
  
}
