//
//  VergeRxTests.swift
//  VergeRxTests
//
//  Created by muukii on 2020/01/09.
//  Copyright © 2020 muukii. All rights reserved.
//

import XCTest

import VergeRx

class VergeRxTests: XCTestCase {
  
  func testChangesObbservable() {
    
    let store = DemoStore()
    
    XCTContext.runActivity(named: "Premise") { (activity) in
      
      XCTAssertEqual(store.state.hasChanges(\.count), true)
      
      store.commit { $0.markAsModified() }
      
      XCTAssertEqual(store.state.hasChanges(\.count), false)
      
    }
    
    XCTContext.runActivity(named: "startsFromInitial: true") { (activity) in
      
      let exp1 = expectation(description: "")
      
      _ = store.rx.stateObservable(startsFromInitial: true)
        .subscribe(onNext: { changes in
          exp1.fulfill()
          XCTAssertEqual(changes.hasChanges(\.count), true)
        })
      
      XCTAssertEqual(exp1.expectedFulfillmentCount, 1)
      
      wait(for: [exp1], timeout: 1)
      
    }
    
    XCTContext.runActivity(named: "startsFromInitial: false") { (activity) in
      
      let exp1 = expectation(description: "")
      
      _ = store.rx.stateObservable(startsFromInitial: false)
        .subscribe(onNext: { changes in
          exp1.fulfill()
          XCTAssertEqual(changes.hasChanges(\.count), false)
        })
      
      XCTAssertEqual(exp1.expectedFulfillmentCount, 1)
      
      wait(for: [exp1], timeout: 1)
      
    }
  }
}
