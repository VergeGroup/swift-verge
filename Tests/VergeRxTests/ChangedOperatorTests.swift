//
//  ChangedOperatorTests.swift
//  VergeRxTests
//
//  Created by muukii on 2020/05/01.
//  Copyright © 2020 muukii. All rights reserved.
//


import Foundation

import XCTest

import VergeRx
import Verge
import VergeORM

@MainActor
class ChangedOperatorTests: XCTestCase {
  
  let store = Store<DemoState, Never>.init(initialState: .init(), logger: nil)
  
  func testChanged() {
    

    let count = store.derived(.map(\.count))
    
    let exp = expectation(description: "")
    exp.assertForOverFulfill = true
    exp.expectedFulfillmentCount = 3
    
    _ = count.rx.valueObservable()
      .changed({ $0.description })
      .subscribe(onNext: { _ in
        exp.fulfill()
      })
    
    store.commit {
      $0.count += 1
    }
    store.commit {
      $0.count += 1
    }
    store.commit { _ in
     
    }
    wait(for: [exp], timeout: 2)
  }
}
