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

struct Counter {
  var read = 0
  var transform = 0
  var hitPrefilter = 0

  mutating func reset() {
    self = Counter()
  }
}

fileprivate var nameCount_derived_counter = Counter()

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

      let nameCount_derived = Field.Computed.init(derive: { $0.name }) { (name) in
        name.count
      }
      .onRead {
        nameCount_derived_counter.read += 1
      }
      .onTransform {
        nameCount_derived_counter.transform += 1
      }
      .onHitPreFilter {
        nameCount_derived_counter.hitPrefilter += 1
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
    
    let changes = store.state
    
    measure {
      _ = changes.computed.filteredArray
    }
    
  }
  
  func testPerformanceComputingWithourPrefilter() {
   
    let store = MyStore()
    
    let changes = store.state
    
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
      _ = store.state.computed.filteredArray
    }
    
  }
  
  func testPerformanceComputingWithourPrefilterWithCommits() {
    
    let store = MyStore()
        
    measure {
      store.commit {
        // no affects to array
        $0.num_1 += 1
      }
      _ = store.state.computed.filteredArrayWithoutPreFilter
    }
    
  }
  
  func testChangesChain() {
    
    let store = MyStore()
        
    XCTAssertEqual(store.state.version, 0)
    XCTAssertNil(store.state.previous)
    
    XCTAssertEqual(store.state.num_0, 0)
    XCTAssertEqual(store.state.hasChanges(\.num_0), true)
    XCTAssertEqual(store.state.hasChanges(\.computed.num_0), true)
                    
    store.commit {
      $0.num_0 = 0
    }
    
    XCTAssertEqual(store.state.hasChanges(\.num_0), false)
    XCTAssertEqual(store.state.hasChanges(\.computed.num_0), false)
    
    store.commit {
      $0.num_0 = 1
    }
        
    XCTAssertEqual(store.state.version, 2)
    XCTAssertNotNil(store.state.previous)
    XCTAssertNil(store.state.previous?.previous)
    
    XCTAssertEqual(store.state.hasChanges(\.num_0), true)
    XCTAssertEqual(store.state.hasChanges(\.computed.num_0), true)

    store.commit {
      $0.num_0 = 2
    }
    
    XCTAssertEqual(store.state.version, 3)
    XCTAssertNotNil(store.state.previous)
    XCTAssertNil(store.state.previous?.previous)
    XCTAssertEqual(store.state.previous?.num_0, 1)
    
    XCTAssertEqual(store.state.hasChanges(\.num_0), true)
    XCTAssertEqual(store.state.hasChanges(\.computed.num_0), true)
    
    store.commit {
      $0.num_0 = 2
    }
    
    XCTAssertEqual(store.state.version, 4)

    XCTAssertEqual(store.state.hasChanges(\.num_0), false)
    XCTAssertEqual(store.state.hasChanges(\.computed.num_0), false)
  }
  
  func testCompose1() {
    
    let store = MyStore()
    
    var count = 0
        
    store.state.ifChanged({ $0.computed.num_0 }, ==) { v in
        count += 1
    }
    
    store.commit {
      $0.num_0 = 0
    }
    
    store.state.ifChanged({ $0.computed.num_0 }, ==) { v in
        count += 1
    }
    
    XCTAssertEqual(count, 1)
    
  }
  
  func testCompose2() {
    
    let store = MyStore()
    
    var count = 0
    
    func ifChange(_ perform: () -> Void) {
      store.state.ifChanged(
        {
          (
            $0.num_1,
            $0.num_0,
            $0.computed.num_0
          )
      },
        ==) { _ in
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
    
    _ = store.state.num_0
    store.commit {
      $0.markAsModified()
    }

    let changes = store.state
                  
    measure {
      DispatchQueue.concurrentPerform(iterations: 500) { (i) in
        XCTAssertEqual(changes.hasChanges(\.computed.num_0), false)
      }
    }
    
  }
  
  func testMinimumizeComupting() {
    
    let store = MyStore()
    let changes = store.state
    
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
            
    let sub = store.sinkState(queue: .passthrough) { (changes) in
      
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
    
    withExtendedLifetime(sub, {})
    
  }
    
  func testRetainCylcle() {
    
    var store: MyStore! = MyStore()
    weak var _store = store
    
    let subscription = store.sinkState(queue: .passthrough) { (changes) in

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
    
    withExtendedLifetime(subscription, {})
  }

  func testDerivedInitializer() {

    let store = MyStore()

    nameCount_derived_counter.reset()

    XCTAssertEqual(store.state.computed.nameCount_derived, "muukii".count)
    XCTAssertEqual(nameCount_derived_counter.read, 1)
    XCTAssertEqual(nameCount_derived_counter.transform, 1)
    XCTAssertEqual(nameCount_derived_counter.hitPrefilter, 0)

    // commit unreated value
    store.commit {
      $0.num_0 += 1
    }

    XCTAssertEqual(store.state.computed.nameCount_derived, "muukii".count)
    XCTAssertEqual(nameCount_derived_counter.read, 2)
    XCTAssertEqual(nameCount_derived_counter.transform, 1)
    XCTAssertEqual(nameCount_derived_counter.hitPrefilter, 1)

    // commit reated value
    store.commit {
      $0.name = "H"
    }

    XCTAssertEqual(store.state.computed.nameCount_derived, "H".count)
    XCTAssertEqual(nameCount_derived_counter.read, 3)
    XCTAssertEqual(nameCount_derived_counter.transform, 2)
    XCTAssertEqual(nameCount_derived_counter.hitPrefilter, 1)

  }
}
