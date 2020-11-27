//
//  VergeTests.swift
//  VergeTests
//
//  Created by muukii on 11/10/17.
//  Copyright © 2017 muukii. All rights reserved.
//

import XCTest

import RxSwift
@testable import VergeClassic

class VergeTests: XCTestCase {

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

      let state: Storage<State> = .init(.init())

      var updated: Bool = false

      _ = state
        .changed(\.name1)
        .skip(1)
        .bind { _ in
          updated = true
        }

      let newName: String = "mmm"

      state.update {
        $0.name1 = newName
      }

      XCTAssertEqual(updated, true)

    }

    XCTContext.runActivity(named: "Set same value, target is non-optional") { _ in

      let state: Storage<State> = .init(.init())

      var updated: Bool = false

      _ = state
        .changed(\.name1)
        .skip(1)
        .bind { _ in
          updated = true
        }

      let newName: String = ""

      state.update {
        $0.name1 = newName
      }
      
      XCTAssertEqual(updated, false)
    }

    XCTContext.runActivity(named: "Set changed value, target is optional") { _ in

      let state: Storage<State> = .init(.init())

      var updated: Bool = false

      _ = state
        .changed(\.name2)
        .skip(1)
        .bind { _ in
          updated = true
      }

      state.update {
        $0.name2 = "hoo"
      }

      XCTAssertEqual(updated, true)
    }

    XCTContext.runActivity(named: "Set same value, target is optional") { _ in

      let state: Storage<State> = .init(.init())
      
      var updated: Bool = false

      _ = state
        .changed(\.name2)
        .skip(1)
        .bind { _ in
          updated = true
      }
      
      state.update {
        $0.name2 = nil
      }

      XCTAssertEqual(updated, false)
    }

  }

  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }

  func testPerformanceDispatchCommit() {

    let vm = ViewModel()

    self.measure {
      vm.increment()
    }
  }

}

extension VergeTests {

  final class ViewModel : VergeType {

    final class State {
      var count: Int = 0
    }

    enum Activity {

    }

    let state: Storage<State> = .init(.init())

    init() {

    }

    func increment() {

      dispatch { c in
        c.commit { s in
          s.count += 1
        }
      }
    }

  }
}
