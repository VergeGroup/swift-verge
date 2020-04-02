//
//  ComputedTests.swift
//  VergeStore
//
//  Created by muukii on 2020/03/31.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest
import VergeStore

#if canImport(Combine)

@available(iOS 13, macOS 10.15, *)
class ComputedTests: XCTestCase {
  
  struct MyStoreState: CombinedStateType {
        
    var name: String = "muukii"
    
    struct Getters: GettersType {
      
      let nameCount = Field.Computed<Int>.init {
        $0.mapWithoutPreFilter(\.name.count).build()
      }
      
    }
  }
  
  @available(iOS 13, *)
  final class MyStore: StoreBase<MyStoreState, Never> {
            
    init() {
      super.init(initialState: .init(), logger: nil)
    }
    
  }
  
  func testRetainCylcle() {
    
    var store: MyStore! = MyStore()
    weak var _store = store
            
    XCTAssertEqual(store.computed.nameCount, 6)
    XCTAssertEqual(store.getters.nameCount.value, 6)

    store = nil
    XCTAssertNil(_store)
  }
  
}

#endif
