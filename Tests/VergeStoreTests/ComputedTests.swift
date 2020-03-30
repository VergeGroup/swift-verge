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
  
  struct MyStoreState: StateType {
    
    var hoge: Int = 0
  }
  
  @available(iOS 13, *)
  final class MyStore: StoreBase<MyStoreState, Never> {
    
    @Field.Computed var count: Int
    
    init() {
      self._count = .init(make: { (chain) -> Getter<Int> in
        chain.mapWithoutPreFilter(\.hoge).build()
      })
      
      super.init(initialState: .init(), logger: nil)
    }
    
  }
  
  func testRetainCylcle() {
    
    var store: MyStore! = MyStore()
    weak var _store = store
    
    XCTAssertEqual(store.count, 0)
    XCTAssertEqual(store.$count.value, 0)
    
    store = nil
    
    XCTAssertNil(_store)
    
  }

  
}

#endif
