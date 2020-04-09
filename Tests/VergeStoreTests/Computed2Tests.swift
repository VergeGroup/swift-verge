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

fileprivate var rootTransformCounter: Int = 0
fileprivate var nestedCounter: Int = 0
fileprivate var rootReadCounter = 0
fileprivate var rootPreFilterCounter = 0

class Computed2Tests: XCTestCase {
  
  struct RootState: CombinedStateType {
    
    var name: String = "muukii"
    
    var foo: String {
      name
    }
    
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
        .onPreFilter {
          rootPreFilterCounter += 1
      }
      .onRead { _ in
        rootReadCounter += 1
      }
      .onTransform { o in
        print(o)
        rootTransformCounter += 1
      }
      
    }
  }
  
  final class MyStore: StoreBase<RootState, Never> {
    
    init() {
      super.init(initialState: .init(), logger: nil)
    }
    
  }
  
  override func setUp() {
    rootTransformCounter = 0
    nestedCounter = 0
  }
  
  func testPreFilterCount() {
    
    let store = MyStore()
    
    store.subscribeStateChanges { (changes) in
      
      _ = changes.computed.nameCount
      _ = changes.computed.nameCount
      _ = changes.computed.nameCount
          
    }
    
    XCTAssertEqual(rootPreFilterCounter, 0)
    XCTAssertEqual(rootReadCounter, 3)
    XCTAssertEqual(rootTransformCounter, 1)
    
    store.commit {
      $0.name = "a"
    }
    
    XCTAssertEqual(rootPreFilterCounter, 1)
    XCTAssertEqual(rootReadCounter, 6)
    XCTAssertEqual(rootTransformCounter, 2)
    
    store.commit {
      $0.name = "a"
    }
    
    XCTAssertEqual(rootPreFilterCounter, 2)
    XCTAssertEqual(rootReadCounter, 9)
    XCTAssertEqual(rootTransformCounter, 2)
    
    
  }
    
  func testRetainCylcle() {
    
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
      
      changes.ifChanged(computed: \.nameCount) { (f) in
        
      }
                          
    }
    
    XCTAssertEqual(rootTransformCounter, 1)
    XCTAssertEqual(nestedCounter, 1)
    
    store.commit {
      $0.name = "John"
    }
    
    XCTAssertEqual(rootTransformCounter, 2)
    XCTAssertEqual(nestedCounter, 1)
    
    store.commit {
      $0.name = "John"
    }
    
    XCTAssertEqual(rootTransformCounter, 2)
    XCTAssertEqual(nestedCounter, 1)
    
    store.commit {
      $0.name = "Matto"
    }
    
    XCTAssertEqual(rootTransformCounter, 3)
    XCTAssertEqual(nestedCounter, 1)
          
    store = nil
    XCTAssertNil(_store)
  }
  
}
