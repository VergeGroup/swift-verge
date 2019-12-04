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
    super.init(initialState: .init(), logger: DefaultLogger.shared)
  }
}

class RootDispatcher: Store.DispatcherType {

}

extension Mutations where Base == RootDispatcher {
  
  func resetCount() {
    descriptor.commit {
      $0.count = 0
    }
  }
  
  func increment() {
    descriptor.commit {
      $0.count += 1
    }
  }
  
  func setNestedState() {
    descriptor.commit {
      $0.optionalNested = .init()
    }
  }
  
  func setMyName() {
    descriptor.commit {
      $0.update(target: \.optionalNested) {
        $0.myName = "Muuk"
      }
    }
  }
  
  func setMyNameUsingTargetingCommit() {
    descriptor.commit(\.optionalNested) {
      $0.myName = "Target"
    }
  }
}

extension Actions where Base == RootDispatcher {
  
  func continuousIncrement() {
    
    descriptor.dispatch { c in
      c.commit.increment()
      c.commit.increment()
    }
    
  }
  
}

final class OptionalNestedDispatcher: Store.DispatcherType, ScopedDispatching {
  var selector: WritableKeyPath<State, State.NestedState?> {
    \.optionalNested
  }
}

extension Mutations where Base == OptionalNestedDispatcher {
     
  func setMyName() {
    descriptor.commitScopedIfPresent {
      $0.myName = "Hello"
    }
  }
  
}

final class NestedDispatcher: Store.DispatcherType, ScopedDispatching {
  
  var selector: WritableKeyPath<State, State.NestedState> {
    \.nested
  }
  
}

extension Mutations where Base == NestedDispatcher {
  
  func setMyName() {
    descriptor.commitScoped {
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
  
  func testDispatch() {
    dispatcher.commit.resetCount()
    dispatcher.dispatch.continuousIncrement()
    XCTAssert(store.state.count == 2)
  }
  
  func testMutatingOptionalNestedState() {
    
    XCTAssert(store.state.optionalNested == nil)
    dispatcher.commit.setNestedState()
    dispatcher.commit.setNestedState()
    XCTAssert(store.state.optionalNested != nil)
    dispatcher.commit.setMyName()
    XCTAssertEqual(store.state.optionalNested?.myName, "Muuk")
    
    let d = OptionalNestedDispatcher(target: store)
    d.commit.setMyName()
    XCTAssertEqual(store.state.optionalNested?.myName, "Hello")
  }
  
  func testMutatingNestedState() {
               
    let d = NestedDispatcher(target: store)
    d.commit.setMyName()
    XCTAssertEqual(store.state.nested.myName, "Hello")
  }
  
  func testIncrement() {
    
    dispatcher.commit.increment()
    XCTAssertEqual(store.state.count, 1)
    
  }
  
  func testTargetingCommit() {
    
    dispatcher.commit.setNestedState()
    dispatcher.commit.setMyNameUsingTargetingCommit()
    XCTAssertEqual(store.state.optionalNested?.myName, "Target")
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}
