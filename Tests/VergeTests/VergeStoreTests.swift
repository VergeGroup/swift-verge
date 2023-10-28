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
      
  struct _State: Equatable, StateType {

    static func reduce(
      modifying: inout Self,
      current: Changes<Self>,
      transaction: inout Transaction
    ) {}

    struct TreeA {
      
    }
    
    struct TreeB {
      
    }
    
    struct TreeC {
      
    }
    
    struct NestedState: Equatable {
      
      var myName: String = ""
    }
    
    struct OptionalNestedState: Equatable {
      
      var myName: String = ""
    }
    
    var count: Int = 0
    var optionalNested: OptionalNestedState?
    var nested: NestedState = .init()
    
    @Edge var treeA = TreeA()
    @Edge var treeB = TreeB()
    @Edge var treeC = TreeC()
    
  }
  
  final class _Store: Verge.Store<_State, Never> {

    init() {
      super.init(initialState: .init(), logger: DefaultStoreLogger.shared)
    }
  }
  
  class RootDispatcher: DispatcherType {

    enum Error: Swift.Error {
      case something
    }

    var scope: WritableKeyPath<VergeStoreTests._State, VergeStoreTests._State> {
      \.self
    }

    let store: _Store

    init(store: _Store) {
      self.store = store
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
        let _: State.NestedState = state
        
      }
        
      let optionalNestedTarget = detached(from: \.optionalNested)
                  
      let _: Changes<State.OptionalNestedState?> = optionalNestedTarget.state
          
      optionalNestedTarget.commit { state in
        let _: State.OptionalNestedState? = state
      }
                      
    }
    
  }
  
  /**
   Use Edge due to TreeA does not have Equatable.
   */
  final class TreeADispatcher: DispatcherType {

    let store: _Store
    let scope: WritableKeyPath<VergeStoreTests._State, Edge<_State.TreeA>> = \.$treeA

    init(store: _Store) {
      self.store = store
    }
    
    func operation() {
      
      let _: Changes<Edge<_State.TreeA>> = state
      
      commit { state in
        let _: Edge<_State.TreeA> = state
      }
      
      let treeB = detached(from: \.$treeB)
      
      let _: Changes<Edge<_State.TreeB>> = treeB.state
                         
      treeB.commit { state in
        let _: Edge<_State.TreeB> = state
      }
         
    }
  }
  
  let store = _Store()
  lazy var dispatcher = RootDispatcher(store: self.store)

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
    
    var subscriptions = Set<AnyCancellable>()
    var count = 0
    
    store.sinkState(queue: .passthrough) { (changes) in
      count += 1
    }
    .store(in: &subscriptions)
        
    store.commit {
      $0.count += 1
    }
    
    // stop subscribing
    subscriptions = .init()

    store.commit {
      $0.count += 1
    }
    
    XCTAssertEqual(count, 2)
    
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
      
      _ = store.statePublisher()
        .sink { changes in
          exp1.fulfill()
          XCTAssertEqual(changes.hasChanges(\.count), true)
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

  final class DemoStoreWrapper2: StoreWrapperType {

    struct State: Equatable {
      var source: Changes<Int>
    }

    let store: Verge.Store<State, Never>
    var sub: StoreSubscription? = nil

    init(sourceStore: DemoStore) {

      let d = sourceStore
        .derived(.map(\.count), queue: .passthrough)

      self.store = .init(initialState: .init(source: d.state), logger: nil)

      sub = d.assign(to: store.assignee(\.source))

    }

  }
  
  func testAsignee2() {

    let store1 = DemoStore()
    let store2 = DemoStoreWrapper2(sourceStore: store1)

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
   
  func testMapIfPresent() {
    
    let store = _Store()
    
    XCTAssert(store.state.optionalNested == nil)
    
    do {
      
      let state = store.state
      
      if let _ = state.mapIfPresent(\.optionalNested) {
        XCTFail()
      }
      
    }
    
    store.commit {
      $0.optionalNested = .init()
    }
    
    do {
      
      let state = store.state
      
      if let nested = state.mapIfPresent(\.optionalNested) {
        XCTAssert(nested.previous == nil)
      } else {
        XCTFail()
      }
      
    }
    
    store.commit {
      $0.optionalNested!.myName = "hello"
    }
    
    do {
      
      let state = store.state
      
      if let nested = state.mapIfPresent(\.optionalNested) {
        XCTAssert(nested.previous != nil)
      } else {
        XCTFail()
      }
      
    }
  }

  func testChangesSwiftUIBinding() {
    let store = _Store()
    let binding = store.binding(\.count)

    binding.wrappedValue = 5
    XCTAssertEqual(store.state.count, 5)

    store.commit {
      $0.count = 10
    }
    XCTAssertEqual(binding.wrappedValue, 10)
  }

}
