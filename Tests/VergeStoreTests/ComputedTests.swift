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
  
  struct RootState: ExtendedStateType {
    
    var num_0: Int = 0
    var num_1: Int = 0
    var num_2: Int = 0
    
    var name: String = "muukii"
    
    var largeArray: [Int] = Array((0..<10000).map { $0 })
    
    var foo: String {
      name
    }
    
    var nested: NestedState = .init()
    
    struct NestedState: ExtendedStateType {
      
      var value: String = "Hello"
      
      struct Extended: ExtendedType {
        
        static let instance = Extended()
             
        let nameCount = Field.Computed(\.value.count)
          .dropsInput {
            $0.noChanges(\.value)
        }
        .onTransform {
          nestedCounter += 1
        }
                         
      }
    }
    
    struct Extended: ExtendedType {
      
      static let instance = Extended()
              
      let filteredArray = Field.Computed<[Int]> {
        $0.largeArray.filter { $0 > 300 }
      }
      .dropsInput {
        $0.noChanges(\.largeArray)
      }
      
      let filteredArrayWithoutPreFilter = Field.Computed<[Int]> {
        $0.largeArray.filter { $0 > 300 }
      }
      
      let num_0 = Field.Computed<Int>(\.num_0)
        .dropsInput {
          $0.noChanges(\.num_0)
      }
      .onTransform {
        rootTransformCounter += 1
      }
      
      let num_1 = Field.Computed<Int>(\.num_1)
        .dropsInput {
          $0.noChanges(\.num_1)
      }
      
      let num_2 = Field.Computed<Int>(\.num_2)
        .dropsInput {
          $0.noChanges(\.num_2)
      }
      
      let multiplied = Field.Computed<Int> {
        $0.computed.num_1 * $0.computed.num_2
      }
      .dropsInput {
        $0.noChanges(\.num_1) && $0.noChanges(\.num_2)
      }
                              
      let _nameCount = Field.Computed {
        $0.name
      }
      .dropsInput {
        $0.noChanges(\.name)
      }
      
      let nameCount = Field.Computed(\.name.count)
        .dropsInput {
          $0.noChanges(\.name)
      }
        .onHitPreFilter {
          rootPreFilterCounter += 1
      }
      .onRead {
        rootReadCounter += 1
      }
      .onTransform {
        rootTransformCounter += 1
      }
      
    }
  }
  
  final class MyStore: Store<RootState, Never> {
    
    init() {
      super.init(initialState: .init(), logger: nil)
    }
    
  }
  
  override func setUp() {
    rootTransformCounter = 0
    nestedCounter = 0
  }
  
  func testPerformanceComputing() {
    
    let store = MyStore()
    
    let changes = store.changes
    
    measure {
      _ = changes.computed.filteredArray
    }
    
  }
  
  func testPerformanceComputingWithourPrefilter() {
   
    let store = MyStore()
    
    let changes = store.changes
    
    measure {
      _ = changes.computed.filteredArrayWithoutPreFilter
    }
    
  }
  
  func testPerformanceComputingWithCommits() {
    
    let store = MyStore()
        
    measure {
      store.commit {
        // no affects to array
        $0.num_1 += 1
      }
      _ = store.changes.computed.filteredArray
    }
    
  }
  
  func testPerformanceComputingWithourPrefilterWithCommits() {
    
    let store = MyStore()
        
    measure {
      store.commit {
        // no affects to array
        $0.num_1 += 1
      }
      _ = store.changes.computed.filteredArrayWithoutPreFilter
    }
    
  }
  
  func testChangesChain() {
    
    let store = MyStore()
        
    XCTAssertEqual(store.changes.version, 0)
    XCTAssertNil(store.changes.previous)
    
    XCTAssertEqual(store.changes.num_0, 0)
    XCTAssertEqual(store.changes.hasChanges(\.num_0), true)
    XCTAssertEqual(store.changes.hasChanges(\.computed.num_0), true)
                    
    store.commit {
      $0.num_0 = 0
    }
    
    XCTAssertEqual(store.changes.hasChanges(\.num_0), false)
    XCTAssertEqual(store.changes.hasChanges(\.computed.num_0), false)
    
    store.commit {
      $0.num_0 = 1
    }
        
    XCTAssertEqual(store.changes.version, 2)
    XCTAssertNotNil(store.changes.previous)
    XCTAssertNil(store.changes.previous?.value.previous)
    
    XCTAssertEqual(store.changes.hasChanges(\.num_0), true)
    XCTAssertEqual(store.changes.hasChanges(\.computed.num_0), true)

    store.commit {
      $0.num_0 = 2
    }
    
    XCTAssertEqual(store.changes.version, 3)
    XCTAssertNotNil(store.changes.previous)
    XCTAssertNil(store.changes.previous?.value.previous)
    XCTAssertEqual(store.changes.previous?.value.num_0, 1)
    
    XCTAssertEqual(store.changes.hasChanges(\.num_0), true)
    XCTAssertEqual(store.changes.hasChanges(\.computed.num_0), true)
    
    store.commit {
      $0.num_0 = 2
    }
    
    XCTAssertEqual(store.changes.version, 4)

    XCTAssertEqual(store.changes.hasChanges(\.num_0), false)
    XCTAssertEqual(store.changes.hasChanges(\.computed.num_0), false)
  }
  
  func testCompose1() {
    
    let store = MyStore()
    
    var count = 0
        
    store.changes.ifChanged(
      compose: { $0.computed.num_0 },
      comparer: ==) { v in
        count += 1
    }
    
    store.commit {
      $0.num_0 = 0
    }
    
    store.changes.ifChanged(
      compose: { $0.computed.num_0 },
      comparer: ==) { v in
        count += 1
    }
    
    XCTAssertEqual(count, 1)
    
  }
  
  func testCompose2() {
    
    let store = MyStore()
    
    var count = 0
    
    func ifChange(_ perform: () -> Void) {
      store.changes.ifChanged(
        compose: {
          (
            $0.num_1,
            $0.num_0,
            $0.computed.num_0
          )
      },
        comparer: ==) { _ in
          perform()
      }
    }
        
    XCTContext.runActivity(named: "initial") { (a) -> Void in
      
      ifChange {
        count += 1
      }
           
    }
    
    XCTContext.runActivity(named: "commit1") { (a) -> Void in
      
      store.commit {
        $0.num_0 = 0
      }
      
      ifChange {
        count += 1
      }
      
    }
               
    XCTContext.runActivity(named: "commit2") { (a) -> Void in
      
      store.commit {
        $0.num_0 = 1
      }
      
      ifChange {
        count += 1
      }
      
    }
    
       
    XCTAssertEqual(count, 2)
    
  }
  
  func testConcurrency() {
    
    let store = MyStore()
    
    _ = store.changes.num_0
    store.commit { _ in }

    let changes = store.changes
                  
    measure {
      DispatchQueue.concurrentPerform(iterations: 500) { (i) in
        XCTAssertEqual(changes.hasChanges(\.computed.num_0), false)
      }
    }
    
  }
  
  func testMinimumizeComupting() {
    
    let store = MyStore()
    let changes = store.changes
    
    store.commit { _ in }
    
    rootTransformCounter = 0
    DispatchQueue.concurrentPerform(iterations: 500) { (i) in
      _ = changes.computed.num_0
      XCTAssertEqual(changes.hasChanges(\.computed.num_0), true)
    }
    XCTAssertEqual(rootTransformCounter, 1)
  }
  
  func testPreFilterCount() {
    
    let store = MyStore()
            
    let sub = store.subscribeChanges { (changes) in
      
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
    
    XCTAssertEqual(rootPreFilterCounter, 0)
    XCTAssertEqual(rootReadCounter, 6)
    XCTAssertEqual(rootTransformCounter, 2)
    
    store.commit {
      $0.name = "a"
    }
    
    XCTAssertEqual(rootPreFilterCounter, 1)
    XCTAssertEqual(rootReadCounter, 9)
    XCTAssertEqual(rootTransformCounter, 2)
    
    
  }
    
  func testRetainCylcle() {
    
    var store: MyStore! = MyStore()
    weak var _store = store
    
    let subscription = store.subscribeChanges { (changes) in

      _ = changes.computed.nameCount
      _ = changes.computed.nameCount
      _ = changes.computed.nameCount
      
      _ = changes.map(\.nested)
        .computed
        .nameCount
            
      _ = changes.map(\.nested)
        .computed
        .nameCount
      
      changes.ifChanged(\.computed.nameCount) { (f) in
        
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
