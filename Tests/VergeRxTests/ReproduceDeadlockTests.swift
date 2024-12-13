//
//  ReproduceDeadlockTests.swift
//  VergeStoreTests
//
//  Created by muukii on 2020/04/20.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest
import Verge
import VergeRx

class ReproduceDeadlockTests: XCTestCase {
  
  final class StoreWrapper: StoreDriverType, Sendable {

    struct State: Equatable {
      var count = 0
    }
        
    let store = Store<State, Never>.init(initialState: .init(), logger: nil)

    init() {
    }
  }
  
  func testReproduceDeadlock() {
    
    let store = StoreWrapper()
        
    _ = store.rx.stateObservable().bind { state in
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
