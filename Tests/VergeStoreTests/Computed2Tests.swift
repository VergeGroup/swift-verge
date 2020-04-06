//
//  Computed2Tests.swift
//  VergeStoreTests
//
//  Created by muukii on 2020/04/06.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest
import VergeStore

fileprivate var rootCounter: Int = 0
fileprivate var nestedCounter: Int = 0

class Computed2Tests: XCTestCase {
  
  override func setUp() {
    rootCounter = 0
    nestedCounter = 0
  }
    
  func testRetainCylcle() {
         
    struct RootState: CombinedStateType {
      
      var name: String = "muukii"
      
      var nested: NestedState = .init()
      
      struct NestedState: CombinedStateType {
        
        var value: String = "Hello"
        
        struct Getters: GettersType {
          
          let nameCount = Field.Computed.make()
            .map(\.value.count)
            .ifChanged(keySelector: \.value, comparer: .init(==))
            .onTransform { o in
              print(o)
              nestedCounter += 1
          }
          
        }
      }
      
      struct Getters: GettersType {
        
        let nameCount = Field.Computed.make()
          .map(\.name.count)
          .ifChanged(keySelector: \.name, comparer: .init(==))
          .onTransform { o in
            print(o)
            rootCounter += 1
        }
        
      }
    }
    
    final class MyStore: StoreBase<RootState, Never> {
      
      init() {
        super.init(initialState: .init(), logger: nil)
      }
      
    }
    
    
    var store: MyStore! = MyStore()
    weak var _store = store
    
    store.subscribeStateChanges { (changes) in

      _ = changes.computed.nameCount
      _ = changes.computed.nameCount
      _ = changes.computed.nameCount
      
      _ = changes.map(\.nested)
        .computed
        .nameCount
            
      _ = changes.map(\.nested)
        .computed
        .nameCount
      
    }
    
    XCTAssertEqual(rootCounter, 1)
    XCTAssertEqual(nestedCounter, 1)
    
    store.commit {
      $0.name = "John"
    }
    
    XCTAssertEqual(rootCounter, 2)
    XCTAssertEqual(nestedCounter, 1)
    
    store.commit {
      $0.name = "John"
    }
    
    XCTAssertEqual(rootCounter, 2)
    XCTAssertEqual(nestedCounter, 1)
    
    store.commit {
      $0.name = "Matto"
    }
    
    XCTAssertEqual(rootCounter, 3)
    XCTAssertEqual(nestedCounter, 1)
          
    store = nil
    XCTAssertNil(_store)
  }
  
}
