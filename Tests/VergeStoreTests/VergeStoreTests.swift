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
        c.commit { $0.increment() }
        c.commit { $0.increment() }
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
      dispatcher.commit { $0.increment() }
    }
    
    wait(for: [expectation], timeout: 1)
  }
  
  func testDispatch() {
    
    dispatcher.commit { $0.resetCount() }
    dispatcher.commit { $0.resetCount() }
        
    dispatcher.commit { $0.resetCount() }
    dispatcher.dispatch { $0.continuousIncrement() }
    XCTAssert(store.state.count == 2)
  }
  
  func testMutatingOptionalNestedState() {
    
    XCTAssert(store.state.optionalNested == nil)
    dispatcher.commit { $0.setNestedState() }
    dispatcher.commit { $0.setNestedState() }
    XCTAssert(store.state.optionalNested != nil)
    dispatcher.commit { $0.setMyName() }
    XCTAssertEqual(store.state.optionalNested?.myName, "Muuk")
    
    let d = OptionalNestedDispatcher(target: store)
    d.commit { $0.setMyName() }
    XCTAssertEqual(store.state.optionalNested?.myName, "Hello")
  }
  
  func testMutatingNestedState() {
               
    let d = NestedDispatcher(target: store)
    d.commit { $0.setMyName() }
    XCTAssertEqual(store.state.nested.myName, "Hello")
  }
  
  func testIncrement() {
    
    dispatcher.commit { $0.increment() }
    XCTAssertEqual(store.state.count, 1)
    
  }
  
  func testTargetingCommit() {
    
    dispatcher.commit { $0.setNestedState() }
    dispatcher.commit { $0.setMyName() }
    XCTAssertEqual(store.state.optionalNested?.myName, "Muuk")
  }
  
  func testReturnAnyValueFromMutation() {
    
    let r = dispatcher.commit { $0.returnSomeValue() }
    
    XCTAssertEqual(r, "Hello, Verge")
    
  }
  
}
