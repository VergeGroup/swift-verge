//
//  VergeStoreTests.swift
//  VergeStoreTests
//
//  Created by muukii on 2019/11/04.
//  Copyright © 2019 muukii. All rights reserved.
//

import XCTest

import Verge

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
    
    @Edge var treeA = TreeA()
    @Edge var treeB = TreeB()
    @Edge var treeC = TreeC()
    
  }
  
  final class Store: Verge.Store<State, Never> {
    
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
        if $0.optionalNested != nil {
          $0.optionalNested?.myName = "Muuk"
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
      
      let _: Changes<State.NestedState> = _detached.state
      
      _detached.commit { state in
        let _: InoutRef<State.NestedState> = state
        
      }
        
      let optionalNestedTarget = detached(from: \.optionalNested)
                  
      let _: Changes<State.OptionalNestedState?> = optionalNestedTarget.state
          
      optionalNestedTarget.commit { state in
        let _: InoutRef<State.OptionalNestedState?> = state
      }
                      
    }
    
  }
  
  final class TreeADispatcher: Store.ScopedDispatcher<State.TreeA> {
    
    init(store: Store) {
      super.init(targetStore: store, scope: \.treeA)
    }
    
    func operation() {
      
      let _: Changes<State.TreeA> = state
      
      commit { state in
        let _: InoutRef<State.TreeA> = state
      }
      
      commit(scope: \.treeB) { state in
        let _: InoutRef<State.TreeB> = state
      }
      
      let treeB = detached(from: \.treeB)
      
      let _: Changes<State.TreeB> = treeB.state
                         
      treeB.commit { state in
        let _: InoutRef<State.TreeB> = state
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

  func testCommit() {

    let store = DemoStore()

    store.commit {
      $0.count = 100
    }

    XCTAssertEqual(store.state.count, 100)

    store.commit {
      $0.inner.name = "mmm"
    }

    XCTAssertEqual(store.state.inner.name, "mmm")

    let exp = expectation(description: "async")

    DispatchQueue.global().async {
      store.commit {
        $0.inner.name = "xxx"
      }
      XCTAssertEqual(store.state.inner.name, "xxx")
      exp.fulfill()
    }

    wait(for: [exp], timeout: 1)

  }

  func testEmptyCommit() {

    let store = DemoStore()

    var count = 0

    let subs = store.sinkState(queue: .passthrough) { (_) in
      count += 1
    }

    XCTAssertEqual(store.state.version, 0)

    store.commit {
      $0.count = 100
    }

    XCTAssertEqual(store.state.version, 1)

    store.commit { _ in

    }

    // no changes
    XCTAssertEqual(store.state.version, 1)

    store.commit {
      // explict marking
      $0.markAsModified()
    }

    // many times calling empty commits
    for _ in 0..<3 {
      store.commit { _ in }
    }

    // no affects from read a value
    store.commit {
      if $0.count > 100 {
        $0.count = 0
        XCTFail()
      }
    }

    XCTAssertEqual(store.state.version, 2)
    XCTAssertEqual(count, 3)

    withExtendedLifetime(subs, {})
    
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
    
    store.sinkState(queue: .passthrough) { (changes) in
      count += 1
    }
    .store(in: &subscriptions)
        
    store.commit {
      $0.markAsModified()
    }
    
    subscriptions = .init()

    store.commit {
      $0.markAsModified()
    }
    
    XCTAssertEqual(count, 2)
    
  }
  
  func testOrderOfEvents() {
    
    // Currently, it's collapsed because Storage emits event without locking.
    
    let store = Verge.Store<DemoState, Never>(initialState: .init(), logger: nil)
    
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
      
      store.commit {
        $0.count = $0.count
      }
      
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

  func testAsigneeFromStore() {

    let store1 = DemoStore()
    let store2 = DemoStore()

    let sub = store1
      .assign(to: store2.assignee(\.self))

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


  func testAsigneeFromDerived() {
    
    let store1 = DemoStore()
    let store2 = DemoStore()
    
    let sub = store1
      .derived(.map(\.count), queue: .passthrough)
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
          .derived(.map(\.count), queue: .passthrough)
        
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

    let subscription = store1.sinkState(scan: Scan(seed: 0, accumulator: { v, c in v += 1 })) { changes, accumulated in
      XCTAssertEqual(accumulated, 1)
      expect.fulfill()
    }

    withExtendedLifetime(subscription) {}
    wait(for: [expect], timeout: 1)
  }

  func testBatchCommits() {

    let store1 = DemoStore()

    XCTAssertEqual(store1.state.version, 0)

    store1.batchCommit { (context) in
      context.commit {
        $0.count += 1
      }
    }

    XCTAssertEqual(store1.state.version, 1)

  }

  func testBatchCommitsNoCommits() {

    let store1 = DemoStore()

    XCTAssertEqual(store1.state.version, 0)

    store1.batchCommit { (context) in
      if false {
        context.commit {
          $0.count += 1
        }
      }
    }

    XCTAssertEqual(store1.state.version, 0)

  }

  func testRecursiveCommit() {

    let store1 = DemoStore()

    let exp = expectation(description: "11")

    let cancellable = store1.sinkState { [weak store1] state in

      state.ifChanged(\.count) { value in
        if value == 10 {
          store1?.commit {
            $0.count = 11
          }
        }
        if value == 11 {
          exp.fulfill()
        }
      }
    }

    store1.commit {
      $0.count = 10
    }

    wait(for: [exp], timeout: 1)
    withExtendedLifetime(cancellable) {}

  }

  func testTargetQueue() {

    let store1 = DemoStore()

    let exp = expectation(description: "11")
    var count = 0

    DispatchQueue.global().async {

      let cancellable = store1.sinkState(queue: .startsFromCurrentThread(andUse: .mainIsolated())) { state in

        defer {
          count += 1
        }

        if count == 0 {
          XCTAssertEqual(Thread.isMainThread, false)
        } else {
          XCTAssertEqual(Thread.isMainThread, true)
          exp.fulfill()
        }

      }

      store1.commit {
        $0.count = 10
      }

      withExtendedLifetime(cancellable) {}
    }

    wait(for: [exp], timeout: 1)

  }
  
}
