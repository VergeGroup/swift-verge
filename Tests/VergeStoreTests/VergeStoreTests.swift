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
    
    struct TreeA {
      
    }
    
    struct TreeB {
      
    }
    
    struct TreeC {
      
    }
    
    struct NestedState {
      
      var myName: String = ""
    }
    
    struct OptionalNestedState {
      
      var myName: String = ""
    }
    
    var count: Int = 0
    var optionalNested: OptionalNestedState?
    var nested: NestedState = .init()
    
    @Fragment var treeA = TreeA()
    @Fragment var treeB = TreeB()
    @Fragment var treeC = TreeC()
    
  }
  
  final class Store: StoreBase<State, Never> {
    
    init() {
      super.init(initialState: .init(), logger: DefaultStoreLogger.shared)
    }
  }
  
  class RootDispatcher: Store.Dispatcher {
    
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
    
    func hoge() {
      
      dispatch(scope: \.nested) { (c) -> Void in
        
        let _: State.NestedState = c.state
        
        c.commit { state in
          let _: State.NestedState = state
          
        }
        
        c.dispatch(scope: \.optionalNested) { c in
          
          let _: State.OptionalNestedState? = c.state
          
          c.commit { state in
            let _: State.OptionalNestedState? = state
            
          }
          
        }
                
      }
      
    }
    
  }
  
  final class TreeADispatcher: Store.ScopedDispatcher<State.TreeA> {
    
    init(store: Store) {
      super.init(targetStore: store, scope: \.treeA)
    }
    
    func operation() {
      commit { state in
        let _: State.TreeA = state
      }
      
      commit(scope: \.treeB) { state in
        let _: State.TreeB = state
      }
      
      dispatch { context in
        let _: State.TreeA = context.state
        
        context.commit { state in
          let _: State.TreeA = state
        }
      }
      
      dispatch(scope: \.treeB) { context in
        let _: State.TreeB = context.state
        
        context.commit { state in
          let _: State.TreeB = state
        }
      }
      
      dispatch { context in

        context.dispatch { _context in
           let _: State.TreeA = _context.state
        }
        
        context.dispatch(scope: \.treeB) { _context in
          let _: State.TreeB = _context.state
        }
      }
      
    }
  }
  
  final class OptionalNestedDispatcher: Store.Dispatcher {
   
    func setMyName() {
      commit(scope: \.optionalNested) {
        $0?.myName = "Hello"
      }
    }
    
  }
  
  final class NestedDispatcher: Store.Dispatcher {
    
    func setMyName() {
       commit(scope: \.nested) { (s) in
        s.myName = "Hello"
      }
    }
    
  }
    
  let store = Store()
  lazy var dispatcher = RootDispatcher(targetStore: self.store)
  
  var subs = Set<AnyCancellable>()
  
  override func setUp() {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func testScope() {
    
    let store = Store()
    
  }
  
  @available(iOS 13.0, *)
  func testStateSubscription() {
    
    let store = Store()
    let dispatcher = RootDispatcher(targetStore: store)
    
    let expectation = XCTestExpectation()
            
    let getter = store.getterBuilder().mapWithoutPreFilter { $0 }.build()
    
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
    
    let d = OptionalNestedDispatcher(targetStore: store)
    d.setMyName()
    XCTAssertEqual(store.state.optionalNested?.myName, "Hello")
  }
  
  func testMutatingNestedState() {
               
    let d = NestedDispatcher(targetStore: store)
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
