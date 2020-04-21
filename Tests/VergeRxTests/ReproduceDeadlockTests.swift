//
//  ReproduceDeadlockTests.swift
//  VergeStoreTests
//
//  Created by muukii on 2020/04/20.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest
import VergeStore
import VergeRx

class ReproduceDeadlockTests: XCTestCase {
  
  class StoreWrapper: StoreWrapperType {
        
    struct State: StateType {
      var count = 0
    }
    
    enum Activity {}
    
    let store = DefaultStore.init(initialState: .init(), logger: nil)
    
  }
  
  func testReproduceDeadlock() {
    
    let store = StoreWrapper()
    
    wait(for: [], timeout: 1)
    
    _ = store.rx.stateObservable.bind { state in
      if state.count == 1 {
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global().async {
          store.commit { $0.count += 1 }
          group.leave()
        }
        group.wait()
      }
    }
        
    store.commit {
      $0.count += 1
    }
    
        
  }
}
