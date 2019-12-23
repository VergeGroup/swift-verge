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

final class Store: StoreBase<State, Never> {
  
  init() {
    super.init(initialState: .init(), logger: DefaultLogger.shared)
  }
}

class RootDispatcher: DispatcherBase<State, Never> {
  
  func resetCount() -> Mutation<Void> {
    return .mutation { s in
      s.count = 0
    }
  }
  
  func increment() -> Mutation<Void> {
    .mutation {
      $0.count += 1
    }
  }
  
  func setNestedState() -> Mutation<Void> {
    .mutation {
      $0.optionalNested = .init()
    }
  }
  
  func setMyName() -> Mutation<Void> {
    .mutation {
      try? $0.updateTryPresent(target: \.optionalNested) {
        $0.myName = "Muuk"
      }
    }
  }
  
  func returnSomeValue() -> Mutation<String> {
    return .mutation { _ in
      return "Hello, Verge"
    }
  }
        
  func continuousIncrement() -> Action<Void> {
    return .action { c in     
      c.accept { $0.increment() }
      c.accept { $0.increment() }
    }
  }
  
}

final class OptionalNestedDispatcher: DispatcherBase<State, Never> {
       
  func setMyName() -> Mutation<Void> {
    return .mutation(\.optionalNested) { (s) in
      s?.myName = "Hello"
    }
  }
  
}

final class NestedDispatcher: DispatcherBase<State, Never> {
  
  func setMyName() -> Mutation<Void> {
    return .mutation(\.nested) { (s) in
      s.myName = "Hello"
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
    dispatcher.accept { $0.setMyName() }
    XCTAssertEqual(store.state.optionalNested?.myName, "Muuk")
  }
  
  func testReturnAnyValueFromMutation() {
    
    let r = dispatcher.accept { $0.returnSomeValue() }
    
    XCTAssertEqual(r, "Hello, Verge")
    
  }
  
}
