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

class MemoizeGetterTests: XCTestCase {
  
  struct State: StateType {
       
    var count: Int = 0
    var name: String = ""
  }
  
  final class Store: StoreBase<State, Never> {
    
    init() {
      super.init(initialState: .init(), logger: DefaultLogger.shared)
    }
  }
  
  final class RootDispatcher: DispatcherBase<State, Never> {
        
    func increment() -> Mutation  {
      .mutation {
        $0.count += 1
      }
    }
      
    func setMyName() -> Mutation  {
      .mutation {
        $0.name = UUID().uuidString
      }
    }
        
  }
  
  func testMemoize() {
    
    let store = Store()
    let dispatcher = RootDispatcher(target: store)
    
    var callCount = 0
        
    let getter = store.selector(selector: { (state) -> Int in
      callCount += 1
      return state.count * 2
    }, equality: .init(selector: { $0.count }, equals: ==))
    
    XCTAssertEqual(getter.value, 0)
    
    XCTAssertEqual(callCount, 1)
    
    dispatcher.accept { $0.increment() }
    
    XCTAssertEqual(getter.value, 2)
    
    XCTAssertEqual(callCount, 2)
    
    dispatcher.accept { $0.setMyName() }
    
    XCTAssertEqual(getter.value, 2)
    
    XCTAssertEqual(callCount, 2)
  }
  
}
