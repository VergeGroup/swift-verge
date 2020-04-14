//
//  Computed2Tests.swift
//  VergeStoreTests
//
//  Created by muukii on 2020/04/06.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest
@testable import VergeStore

fileprivate var rootTransformCounter: Int = 0
fileprivate var nestedCounter: Int = 0
fileprivate var rootReadCounter = 0
fileprivate var rootPreFilterCounter = 0

class Computed2Tests: XCTestCase {
  
  struct RootState: CombinedStateType {
    
    var num_0: Int = 0
    var num_1: Int = 0
    var num_2: Int = 0
    
    var name: String = "muukii"
    
    var foo: String {
      name
    }
    
    var nested: NestedState = .init()
    
    struct NestedState: CombinedStateType {
      
      var value: String = "Hello"
      
      struct Getters: GettersType {
        
        let nameCount = Field.Computed(\.value.count)
          .ifChanged(keySelector: \.value, comparer: .init(==))
          .onTransform { o in
            print(o)
            nestedCounter += 1
        }
        
      }
    }
    
    struct Getters: GettersType {
      
      let num_0 = Field.Computed<Int>(\.num_0).ifChanged(keySelector: \.num_0, comparer: .init(==))
      var num_1 = Field.Computed<Int>(\.num_1).ifChanged(keySelector: \.num_1, comparer: .init(==))
      var num_2 = Field.Computed<Int>(\.num_2).ifChanged(keySelector: \.num_2, comparer: .init(==))
                              
      let _nameCount = Field.Computed {
        $0.name
      }
      .ifChanged(keySelector: \.name, comparer: .init(==))
      
      let nameCount = Field.Computed(\.name.count)
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
  
  func testChangesChain() {
    
    let store = MyStore()
        
    XCTAssertEqual(store.changes.version, 0)
    XCTAssertNil(store.changes.previous)
    
    XCTAssertEqual(store.changes.num_0, 0)
    XCTAssertEqual(store.changes.hasChanges(\.num_0), true)
    XCTAssertEqual(store.changes.hasChanges(computed: \.num_0), true)
            
    store.commit {
      $0.num_0 = 0
    }
    
    XCTAssertEqual(store.changes.hasChanges(\.num_0), false)
    XCTAssertEqual(store.changes.hasChanges(computed: \.num_0), false)
    
    store.commit {
      $0.num_0 = 1
    }
        
    XCTAssertEqual(store.changes.version, 2)
    XCTAssertNotNil(store.changes.previous)
    XCTAssertNil(store.changes.previous?.value.previous)
    
    XCTAssertEqual(store.changes.hasChanges(\.num_0), true)
    XCTAssertEqual(store.changes.hasChanges(computed: \.num_0), true)

    store.commit {
      $0.num_0 = 2
    }
    
    XCTAssertEqual(store.changes.version, 3)
    XCTAssertNotNil(store.changes.previous)
    XCTAssertNil(store.changes.previous?.value.previous)
    XCTAssertEqual(store.changes.previous?.value.num_0, 1)
    
    XCTAssertEqual(store.changes.hasChanges(\.num_0), true)
    XCTAssertEqual(store.changes.hasChanges(computed: \.num_0), true)
    
    store.commit {
      $0.num_0 = 2
    }
    
    XCTAssertEqual(store.changes.version, 4)

    XCTAssertEqual(store.changes.hasChanges(\.num_0), false)
    XCTAssertEqual(store.changes.hasChanges(computed: \.num_0), false)
  }
  
  func testCompose() {
    
    let store = MyStore()
    
    store.changes.computed._nameCount
    
    store.changes.ifChanged(compose: {
      (
        $0.name,
        $0.computed._nameCount
      )
    }, comparer: ==) { (hoge) in
      
    }
    
    store.changes.ifChanged(computed: \._nameCount) { hoge in
      
    }
    
  }
  
  func testX() {
    
    let store = MyStore()
    
    store.changes.computed._nameCount
    
    store.changes.ifChanged(computed: \._nameCount) { hoge in
      
    }
    
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
