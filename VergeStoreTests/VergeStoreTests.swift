//
//  VergeStoreTests.swift
//  VergeStoreTests
//
//  Created by muukii on 2019/11/04.
//  Copyright © 2019 muukii. All rights reserved.
//

import XCTest

import VergeStore

struct State: StateType {
  
  struct NestedState {
    
    var myName: String = ""
  }
  
  var count: Int = 0
  var optionalNested: NestedState?
  var nested: NestedState = .init()
}

final class Store: VergeDefaultStore<State> {
  
  init() {
    super.init(initialState: .init(), logger: nil)
  }
}

class RootDispatcher: Store.DispatcherType {
  
  func increment() {
    commit {
      $0.count += 1
    }
  }
  
  func setNestedState() {
    commit {
      $0.optionalNested = .init()
    }
  }
  
  func setMyName() {
    commit {
      $0.updateIfExists(target: \.optionalNested) {
        $0.myName = "Muuk"
      }
    }
  }
}

final class OptionalNestedDispatcher: RootDispatcher, ScopedDispatching {
  
  var selector: WritableKeyPath<State, State.NestedState?> {
    \.optionalNested
  }
  
  override func setMyName() {
    commitIfPresent {
      $0.myName = "Hello"
    }
  }
  
}

final class NestedDispatcher: RootDispatcher, ScopedDispatching {
  
  var selector: WritableKeyPath<State, State.NestedState> {
    \.nested
  }
  
  override func setMyName() {
    commitScoped {
      $0.myName = "Hello"
    }
  }
  
}

final class VergeStoreTests: XCTestCase {
  
  let store = Store()
  lazy var dispatcher = RootDispatcher(target: self.store)
  
  override func setUp() {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func testMutatingOptionalNestedState() {
    
    XCTAssert(store.state.optionalNested == nil)
    dispatcher.setNestedState()
    XCTAssert(store.state.optionalNested != nil)
    dispatcher.setMyName()
    XCTAssertEqual(store.state.optionalNested?.myName, "Muuk")
    
    let d = OptionalNestedDispatcher(target: store)
    d.setMyName()
    XCTAssertEqual(store.state.optionalNested?.myName, "Hello")
  }
  
  func testMutatingNestedState() {
               
    let d = NestedDispatcher(target: store)
    d.setMyName()
    XCTAssertEqual(store.state.nested.myName, "Hello")
  }
  
  func testIncrement() {
    
    dispatcher.increment()
    XCTAssertEqual(store.state.count, 1)
    
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}
