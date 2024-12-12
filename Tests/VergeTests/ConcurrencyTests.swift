//
//  ConcurrencyTests.swift
//  VergeTests
//
//  Created by Muukii on 2021/03/16.
//  Copyright © 2021 muukii. All rights reserved.
//

import Combine
import Foundation
import Verge
import XCTest
import os.lock

@available(iOS 13, *)
final class ConcurrencyTests: XCTestCase {

  func testOrderOfEvents() {
    RuntimeSanitizer.global.isSanitizerStateReceivingByCorrectOrder = true
    RuntimeSanitizer.global.onDidFindRuntimeError = { error in
      print(error)
    }

    // Currently, it's collapsed because Storage emits event without locking.

    let store = Verge.Store<DemoState, Never>(initialState: .init(), logger: nil)

    let exp = expectation(description: "")
    let counter = expectation(description: "update count")
    counter.assertForOverFulfill = true
    counter.expectedFulfillmentCount = 101

    let results: VergeConcurrency.RecursiveLockAtomic<[Int]> = .init([])
    var version: UInt64 = 0

    let sub = store.sinkState(dropsFirst: false) { changes in
      results.modify {
        $0.append(changes.count)
        print("<-", changes.count)
      }
      print("Received version", changes.version)
      XCTAssert(version < changes.version || version == 0)
      version = changes.version
      counter.fulfill()
    }

    let dispatched = VergeConcurrency.UnfairLockAtomic<[Int]>([])

    DispatchQueue.global().async {
      DispatchQueue.concurrentPerform(iterations: 100) { i in

        Task {
          await store.backgroundCommit {
            $0.count = i
            dispatched.modify {
              $0.append(i)
            }
          }
        }
      }

      exp.fulfill()
    }

    wait(for: [exp, counter], timeout: 10)
    //    print(dispatched, results)
    let _dispatched = dispatched.value
    XCTAssertEqual(
      [0] + _dispatched, results.value, "\(([0] + _dispatched).difference(from: results.value))")
    withExtendedLifetime(sub) {}
  }

  func testTargetQueue() {
    let store1 = DemoStore()

    let exp = expectation(description: "11")
    let count = OSAllocatedUnfairLock<Int>.init(initialState: 0)

    DispatchQueue.global().async {
      let cancellable = store1.sinkState(queue: .startsFromCurrentThread(andUse: .mainIsolated())) {
        state in

        defer {
          count.withLock { $0 += 1 }
        }

        if count.withLock({ $0 == 0 }) {
          XCTAssertEqual(Thread.isMainThread, false)
        } else {
          XCTAssertEqual(Thread.isMainThread, true)
          exp.fulfill()
        }
      }

      store1.commit {
        $0.count = 10
      }

      withExtendedLifetime(cancellable) {}
    }

    wait(for: [exp], timeout: 1)
  }

  func testEventOrder() {
    let store = DemoStore()

    var bag = Set<AnyCancellable>()

    for i in 0..<100 {
      do {
        let version = OSAllocatedUnfairLock<UInt64>.init(initialState: 0)
        store.sinkState(queue: .passthrough) { s in
          if version.withLock({ $0 > s.version }) {
            XCTFail()
          }
          version.withLock { $0 = s.version }
          print("\(i)", s.version)
        }
        .store(in: &bag)
      }
    }

    do {
      let version = OSAllocatedUnfairLock<UInt64>.init(initialState: 0)
      store.sinkState(queue: .passthrough) { s in
        if version.withLock({ $0 > s.version }) {
          XCTFail()
        }
        version.withLock { $0 = s.version }
        print("x", s.version)
        store.commit {
          if s.count == 1 {
            $0.count += 1
          }
        }
      }
      .store(in: &bag)
    }

    store.commit { s in
      s.count += 1
    }

    withExtendedLifetime(bag) {}
  }

  func testRecursiveCommit() {
    let store1 = DemoStore()

    let exp = expectation(description: "11")

    let cancellable = store1.sinkState { [weak store1] state in

      state.ifChanged(\.count).do { value in
        if value == 10 {
          store1?.commit {
            $0.count = 11
          }
        }
        if value == 11 {
          exp.fulfill()
        }
      }
    }

    store1.commit {
      $0.count = 10
    }

    wait(for: [exp], timeout: 10)
    withExtendedLifetime(cancellable) {}
  }
}
