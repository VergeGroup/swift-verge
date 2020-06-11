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
      
  struct State {
    
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
  
  final class Store: VergeStore.Store<State, Never> {
    
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
      increment()
      increment()
    }
    
    func failableIncrement() throws {
      try commit { state in
        throw Error.something
      }
    }
    
    func hoge() {
      
      let _detached = detached(from: \.nested)
      
      let _: State.NestedState = _detached.state
      
      _detached.commit { state in
        let _: State.NestedState = state
        
      }
        
      let optionalNestedTarget = detached(from: \.optionalNested)
                  
      let _: State.OptionalNestedState? = optionalNestedTarget.state
          
      optionalNestedTarget.commit { state in
        let _: State.OptionalNestedState? = state
      }
                      
    }
    
  }
  
  final class TreeADispatcher: Store.ScopedDispatcher<State.TreeA> {
    
    init(store: Store) {
      super.init(targetStore: store, scope: \.treeA)
    }
    
    func operation() {
      
      let _: State.TreeA = state
      
      commit { state in
        let _: State.TreeA = state
      }
      
      commit(scope: \.treeB) { state in
        let _: State.TreeB = state
      }
      
      let treeB = detached(from: \.treeB)
      
      let _: State.TreeB = treeB.state
                         
      treeB.commit { state in
        let _: State.TreeB = state
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
    
  func testDispatch() {
    
    dispatcher.resetCount()
    dispatcher.resetCount()
        
    dispatcher.resetCount()
    dispatcher.continuousIncrement()
    XCTAssert(store.primitiveState.count == 2)
  }
  
  func testTryMutation() {
    
    do {
      try dispatcher.failableIncrement()
      XCTFail()
    } catch {
      
    }
    
  }
  
  func testMutatingOptionalNestedState() {
    
    XCTAssert(store.primitiveState.optionalNested == nil)
    dispatcher.setNestedState()
    dispatcher.setNestedState()
    XCTAssert(store.primitiveState.optionalNested != nil)
    dispatcher.setMyName()
    XCTAssertEqual(store.primitiveState.optionalNested?.myName, "Muuk")
    
    let d = OptionalNestedDispatcher(targetStore: store)
    d.setMyName()
    XCTAssertEqual(store.primitiveState.optionalNested?.myName, "Hello")
  }
  
  func testMutatingNestedState() {
               
    let d = NestedDispatcher(targetStore: store)
    d.setMyName()
    XCTAssertEqual(store.primitiveState.nested.myName, "Hello")
  }
  
  func testIncrement() {
    
    dispatcher.increment()
    XCTAssertEqual(store.primitiveState.count, 1)
    
  }
  
  func testTargetingCommit() {
    
    dispatcher.setNestedState()
    dispatcher.setMyName()
    XCTAssertEqual(store.primitiveState.optionalNested?.myName, "Muuk")
  }
  
  func testReturnAnyValueFromMutation() {
    
    let r = dispatcher.returnSomeValue()
    
    XCTAssertEqual(r, "Hello, Verge")
    
  }
  
  func testSubscription() {
    
    var subscriptions = Set<VergeAnyCancellable>()
    var count = 0
    
    store.sinkState { (changes) in
      count += 1
    }
    .store(in: &subscriptions)
        
    store.commit { _ in
      
    }
    
    subscriptions = .init()

    store.commit { _ in
      
    }
    
    XCTAssertEqual(count, 2)
    
  }
  
  func testOrderOfEvents() {
    
    // Currently, it's collapsed because Storage emits event without locking.
    
    let store = VergeStore.Store<DemoState, Never>(initialState: .init(), logger: nil)
    
    let exp = expectation(description: "")
    let counter = expectation(description: "update count")
    counter.assertForOverFulfill = true
    counter.expectedFulfillmentCount = 1001
    
    let results: VergeConcurrency.RecursiveLockAtomic<[Int]> = .init([])
    
    let sub = store.sinkState(dropsFirst: false) { (changes) in
      results.modify {
        $0.append(changes.count)
      }
      counter.fulfill()
    }
    
    DispatchQueue.global().async {
      DispatchQueue.concurrentPerform(iterations: 1000) { (i) in
        store.commit {
          $0.count += 1
        }
        
      }
      exp.fulfill()
    }
           
    wait(for: [exp, counter], timeout: 10)
    XCTAssertEqual(Array((0...1000).map { $0 }), results.value)
    withExtendedLifetime(sub) {}
  }
  
  func testChangesPublisher() {
    
    let store = DemoStore()
    
    XCTContext.runActivity(named: "Premise") { (activity) in
      
      XCTAssertEqual(store.state.hasChanges(\.count), true)
      
      store.commit { _ in }
      
      XCTAssertEqual(store.state.hasChanges(\.count), false)
      
    }
    
    XCTContext.runActivity(named: "startsFromInitial: true") { (activity) in
      
      let exp1 = expectation(description: "")
      
      _ = store.statePublisher(startsFromInitial: true)
        .sink { changes in
          exp1.fulfill()
          XCTAssertEqual(changes.hasChanges(\.count), true)
        }
      
      XCTAssertEqual(exp1.expectedFulfillmentCount, 1)
      
      wait(for: [exp1], timeout: 1)
      
    }
    
    XCTContext.runActivity(named: "startsFromInitial: false") { (activity) in
      
      let exp1 = expectation(description: "")
      
      _ = store.statePublisher(startsFromInitial: false)
        .sink { changes in
          exp1.fulfill()
          XCTAssertEqual(changes.hasChanges(\.count), false)
        }
      
      XCTAssertEqual(exp1.expectedFulfillmentCount, 1)
      
      wait(for: [exp1], timeout: 1)
      
    }
  }
  
  func testAssin() {
    
    let store1 = DemoStore()
    let store2 = DemoStore()
    
    let sub = store1
      .derived(.map(\.count))
      .assign(to: \.count, on: store2)
    
    store1.commit {
      $0.count += 1
    }
    
    XCTAssertEqual(store1.primitiveState.count, store2.primitiveState.count)
    
    store1.commit {
      $0.count += 1
    }
    
    XCTAssertEqual(store1.primitiveState.count, store2.primitiveState.count)
    
    withExtendedLifetime(sub, {})
    
  }
  
  func testAsignee() {
    
    let store1 = DemoStore()
    let store2 = DemoStore()
    
    let sub = store1
      .derived(.map(\.count))
      .assign(to: store2.assignee(\.count))
    
    store1.commit {
      $0.count += 1
    }
    
    XCTAssertEqual(store1.primitiveState.count, store2.primitiveState.count)
    
    store1.commit {
      $0.count += 1
    }
    
    XCTAssertEqual(store1.primitiveState.count, store2.primitiveState.count)
    
    withExtendedLifetime(sub, {})
    
  }
  
  func testAsignee2() {
    
    final class DemoStore2: StoreWrapperType {
      
      typealias Activity = Never
      
      struct State {
        var source: Changes<Int>
      }
      
      let store: DefaultStore
      var sub: VergeAnyCancellable? = nil
      
      init(sourceStore: DemoStore) {
        
        let d = sourceStore
          .derived(.map(\.count))
        
        self.store = .init(initialState: .init(source: d.value), logger: nil)
        
        sub = d.assign(to: assignee(\.source))
        
      }
    }

    
    let store1 = DemoStore()
    let store2 = DemoStore2(sourceStore: store1)
      
    store1.commit {
      $0.count += 1
    }
    
    XCTAssertEqual(store1.primitiveState.count, store2.primitiveState.source.root)
    
    store1.commit {
      $0.count += 1
    }
    
    XCTAssertEqual(store1.primitiveState.count, store2.primitiveState.source.root)
    
  }

  func testScan() {

    let store1 = DemoStore()

    let expect = expectation(description: "")

    let subscription = store.sinkState(scan: Scan(seed: 0, accumulator: { v, c in v += 1 })) { changes, accumulated in
      XCTAssertEqual(accumulated, 1)
      expect.fulfill()
    }

    withExtendedLifetime(subscription) {}
    wait(for: [expect], timeout: 1)
  }
  
}
