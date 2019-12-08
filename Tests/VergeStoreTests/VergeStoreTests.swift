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

final class Store: StoreBase<State> {
  
  init() {
    super.init(initialState: .init(), logger: DefaultLogger.shared)
  }
}

class RootDispatcher: DispatcherBase<State> {
  
  func resetCount() -> Mutation {
    return .mutation { s in
      s.count = 0
    }
  }
  
  func increment() -> Mutation  {
    .mutation {
      $0.count += 1
    }
  }
  
  func setNestedState() -> Mutation  {
    .mutation {
      $0.optionalNested = .init()
    }
  }
  
  func setMyName() -> Mutation  {
    .mutation {
      $0.updateIfPresent(target: \.optionalNested) {
        $0.myName = "Muuk"
      }
    }
  }
  
  func setMyNameUsingTargetingCommit() -> Mutation  {
    .mutationIfPresent(\.optionalNested) {
      $0.myName = "Target"
    }
  }
  
  func continuousIncrement() -> Action<Void> {
    .action { c in
      c.accept { $0.increment() }
      c.accept { $0.increment() }
    }
  }
  
}

final class OptionalNestedDispatcher: DispatcherBase<State>, ScopedDispatching {
      
  static var scopedStateKeyPath: WritableKeyPath<State, State.NestedState?> {
    \.optionalNested
  }
     
  func setMyName() -> Mutation {
    .mutationScopedIfPresent {
      $0.myName = "Hello"
    }
  }
  
}

final class NestedDispatcher: DispatcherBase<State>, ScopedDispatching {
  
  static var scopedStateKeyPath: WritableKeyPath<State, State.NestedState> {
    \.nested
  }
    
  func setMyName() -> Mutation {
    .mutationScoped {
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
    
    dispatcher.accept { $0.resetCount() }
    dispatcher.accept { $0.resetCount() }
        
    dispatcher.accept { $0.resetCount() }
    dispatcher.accept { $0.continuousIncrement() }
    XCTAssert(store.state.count == 2)
  }
  
  func testMutatingOptionalNestedState() {
    
    XCTAssert(store.state.optionalNested == nil)
    dispatcher.accept { $0.setNestedState() }
    dispatcher.accept { $0.setNestedState() }
    XCTAssert(store.state.optionalNested != nil)
    dispatcher.accept { $0.setMyName() }
    XCTAssertEqual(store.state.optionalNested?.myName, "Muuk")
    
    let d = OptionalNestedDispatcher(target: store)
    d.accept { $0.setMyName() }
    XCTAssertEqual(store.state.optionalNested?.myName, "Hello")
  }
  
  func testMutatingNestedState() {
               
    let d = NestedDispatcher(target: store)
    d.accept { $0.setMyName() }
    XCTAssertEqual(store.state.nested.myName, "Hello")
  }
  
  func testIncrement() {
    
    dispatcher.accept { $0.increment() }
    XCTAssertEqual(store.state.count, 1)
    
  }
  
  func testTargetingCommit() {
    
    dispatcher.accept { $0.setNestedState() }
    dispatcher.accept { $0.setMyNameUsingTargetingCommit() }
    XCTAssertEqual(store.state.optionalNested?.myName, "Target")
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}
