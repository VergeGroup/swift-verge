//
//  MemoizeGetterTests.swift
//  VergeStoreTests
//
//  Created by muukii on 2019/12/09.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeStore
import VergeCore

@available(iOS 13, macOS 10.15, *)
class MemoizeGetterTests: XCTestCase {
  
  struct State: StateType {
    
    var count: Int = 0
    var name: String = ""
  }
  
  final class Store: VergeStore.Store<State, Never> {
    
    init() {
      super.init(initialState: .init(), logger: DefaultStoreLogger.shared)
    }
  }
  
  final class RootDispatcher: Store.Dispatcher {
    
    func increment() {
      commit {
        $0.count += 1
      }
    }
    
    func setMyName() {
      commit {
        $0.name = UUID().uuidString
      }
    }
    
  }
  
  func testMemoize() {
    
    let store = Store()
    let dispatcher = RootDispatcher(targetStore: store)
    
    var callCount = 0
    
    let getter = store.getterBuilder()
      .changed(selector: \.count, comparer: .init(==))
      .map { state -> Int in
        callCount += 1
        return state.count * 2
    }
    .build()
    
    XCTAssertEqual(getter.value, 0)
    
    XCTAssertEqual(callCount, 1)
    
    dispatcher.increment()
    
    XCTAssertEqual(getter.value, 2)
    
    XCTAssertEqual(callCount, 2)
    
    dispatcher.setMyName()
    
    XCTAssertEqual(getter.value, 2)
    
    XCTAssertEqual(callCount, 2)
  }
  
}
