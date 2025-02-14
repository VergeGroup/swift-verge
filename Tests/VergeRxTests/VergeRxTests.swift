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
  
  @MainActor
  func testChangesObbservable() {
    
    let store = DemoStore()
    
    XCTContext.runActivity(named: "") { (activity) in
      
      let exp1 = expectation(description: "")
      
      _ = store.rx.stateObservable()
        .subscribe(onNext: { changes in
          exp1.fulfill()
          XCTAssertEqual(changes.hasChanges(\.count), true)
        })
      
      XCTAssertEqual(exp1.expectedFulfillmentCount, 1)
      
      wait(for: [exp1], timeout: 1)
      
    }

  }
}
