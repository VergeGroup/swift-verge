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

class ComputedTests: XCTestCase {
  
  struct MyStoreState: CombinedStateType {
        
    var name: String = "muukii"
    
    struct Getters: GettersType {
      
      let nameCount = Field.RxGetter<Int>.init {
        $0.mapWithoutPreFilter(\.name.count).build()
      }
      
    }
  }
  
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
