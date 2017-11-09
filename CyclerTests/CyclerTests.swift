//
//  CyclerTests.swift
//  CyclerTests
//
//  Created by muukii on 11/10/17.
//  Copyright © 2017 muukii. All rights reserved.
//

import XCTest

import RxSwift
import RxCocoa
@testable import CycleViewModel

class CyclerTests: XCTestCase {

  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  struct State {

    var name1: String = ""
    var name2: String? = nil
  }

  func testUpdate() {

    XCTContext.runActivity(named: "Set changed value, target is non-optional") { _ in

      let _state: MutableStateStorage<State> = .init(.init())
      let state: StateStorage<State> = _state.asStateStorage()

      var updated: Bool = false

      _ = state
        .asDriver(keyPath: \.name1)
        .skip(1)
        .drive(onNext: { _ in
          updated = true
        })

      let newName: String = "mmm"

      _state.updateIfChanged(newName, \.name1)

      XCTAssertEqual(updated, true)

    }

    XCTContext.runActivity(named: "Set same value, target is non-optional") { _ in

      let _state: MutableStateStorage<State> = .init(.init())
      let state: StateStorage<State> = _state.asStateStorage()

      var updated: Bool = false

      _ = state
        .asDriver(keyPath: \.name1)
        .skip(1)
        .drive(onNext: { _ in
          updated = true
        })

      let newName: String = ""

      _state.updateIfChanged(newName, \.name1)

      XCTAssertEqual(updated, false)
    }

    XCTContext.runActivity(named: "Set changed value, target is optional") { _ in

      let _state: MutableStateStorage<State> = .init(.init())
      let state: StateStorage<State> = _state.asStateStorage()

      var updated: Bool = false

      _ = state
        .asDriver(keyPath: \.name2)
        .skip(1)
        .drive(onNext: { _ in
          updated = true
        })

      _state.updateIfChanged("hohi", \.name2)

      XCTAssertEqual(updated, true)
    }

    XCTContext.runActivity(named: "Set same value, target is optional") { _ in

      let _state: MutableStateStorage<State> = .init(.init())
      let state: StateStorage<State> = _state.asStateStorage()

      var updated: Bool = false

      _ = state
        .asDriver(keyPath: \.name2)
        .skip(1)
        .drive(onNext: { _ in
          updated = true
        })

      _state.updateIfChanged(nil, \.name2)

      XCTAssertEqual(updated, false)
    }

  }

  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }

}
