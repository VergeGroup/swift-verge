//
//  VergeStoreTests.swift
//  VergeStoreTests
//
//  Created by muukii on 2019/11/04.
//  Copyright © 2019 muukii. All rights reserved.
//

import XCTest

import VergeStore

import Combine

@available(iOS 13.0, *)
final class VergeStoreTests: XCTestCase {
      
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
      super.init(initialState: .init(), logger: DefaultStoreLogger.shared)
    }
  }
  
  class RootDispatcher: DispatcherBase<State, Never> {
    
    enum Error: Swift.Error {
      case something
    }
    
    func resetCount() {
      return commit { s in
        s.count = 0
      }
    }
    
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
        try? $0.updateTryPresent(target: \.optionalNested) {
          $0.myName = "Muuk"
        }
      }
    }
    
    func returnSomeValue() -> String {
      return commit { _ in
        return "Hello, Verge"
      }
    }
    
    func continuousIncrement() {
      dispatch { c -> Void in
        c.redirect { $0.increment() }
        c.redirect { $0.increment() }
      }
    }
    
    func failableIncrement() throws {
      try commit { state in
        throw Error.something
      }
    }
    
  }
  
  final class OptionalNestedDispatcher: DispatcherBase<State, Never> {
   
    func setMyName() {
      commit(scope: \.optionalNested) {
        $0?.myName = "Hello"
      }
    }
    
  }
  
  final class NestedDispatcher: DispatcherBase<State, Never> {
    
    func setMyName() {
       commit(scope: \.nested) { (s) in
        s.myName = "Hello"
      }
    }
    
  }
    
  let store = Store()
  lazy var dispatcher = RootDispatcher(target: self.store)
  
  var subs = Set<AnyCancellable>()
  
  override func setUp() {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  @available(iOS 13.0, *)
  func testStateSubscription() {
    
    let store = Store()
    let dispatcher = RootDispatcher(target: store)
    
    let expectation = XCTestExpectation()
            
    let getter = store.makeGetter()
    getter
      .dropFirst()
      .sink { (state) in
        
        XCTAssertEqual(state.count, 1)
        expectation.fulfill()
    }
    .store(in: &subs)
    
    DispatchQueue.global().async {
      dispatcher.increment()
    }
    
    wait(for: [expectation], timeout: 1)
  }
  
  func testDispatch() {
    
    dispatcher.resetCount()
    dispatcher.resetCount()
        
    dispatcher.resetCount()
    dispatcher.continuousIncrement()
    XCTAssert(store.state.count == 2)
  }
  
  func testTryMutation() {
    
    do {
      try dispatcher.failableIncrement()
      XCTFail()
    } catch {
      
    }
    
  }
  
  func testMutatingOptionalNestedState() {
    
    XCTAssert(store.state.optionalNested == nil)
    dispatcher.setNestedState()
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
  
  func testTargetingCommit() {
    
    dispatcher.setNestedState()
    dispatcher.setMyName()
    XCTAssertEqual(store.state.optionalNested?.myName, "Muuk")
  }
  
  func testReturnAnyValueFromMutation() {
    
    let r = dispatcher.returnSomeValue()
    
    XCTAssertEqual(r, "Hello, Verge")
    
  }
  
}
