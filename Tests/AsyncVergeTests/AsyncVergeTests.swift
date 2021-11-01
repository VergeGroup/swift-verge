//
//  AsyncVergeTests.swift
//  AsyncVergeTests
//
//  Created by Muukii on 2021/11/02.
//  Copyright © 2021 muukii. All rights reserved.
//

import XCTest

@testable import AsyncVerge

struct State {
  var count: Int = 0
}

func _run() async -> String {
  print("Run", Thread.current)
  return "Value"
}

final class Test: XCTestCase {

  let storage = AsyncStorage<State>(.init())

  func test_1() async {
    async let state1 = storage.read()
    async let state2 = storage.read()
    async let state3 = storage.read()

    print(await storage.value.count)

    await storage.update {
      $0.count += 1
    }

    print(await [state1, state2, state3])
  }

  func test_async_let() async {

    async let v1 = _run()
    async let v2 = _run()
    async let v3 = _run()

    print(await [v1, v2, v3])

  }

  func test_await_let() async {

    let v1 = await _run()
    let v2 = await _run()
    let v3 = await _run()

    print(await [v1, v2, v3])

  }

  @MainActor
  func test_snapshot_datarace() async {

    let exp = expectation(description: "")
    exp.expectedFulfillmentCount = 2

    let storage = self.storage

    Task.detached {
      await withTaskGroup(of: Void.self) {

        for i in 0..<1000 {
          $0.addTask {
            await storage.update {
              $0.count += 1
            }
          }
        }

      }

      exp.fulfill()
      print("✅", self.storage.snapshot.count)
    }

    DispatchQueue.global().async { [self] in
      DispatchQueue.concurrentPerform(iterations: 1000) { _ in
        print(storage.snapshot.count, Thread.current)
      }
      exp.fulfill()
    }

    wait(for: [exp], timeout: 10)

  }

  func test_snapshot_datarace_2() async {

    let storage = self.storage

    await withTaskGroup(of: Void.self) {

      for i in 0..<1000 {
        $0.addTask {
          await storage.update {
            $0.count += 1
          }
        }
      }

    }
  }

  func test_snapshot_concurrent_detached() async {

    let storage = self.storage

    await Task.detached {

      await withTaskGroup(of: Void.self) {

        for i in 0..<1000 {
          $0.addTask {
            await storage.update {
              $0.count += 1
            }
          }
        }

      }
    }
    .result
  }
}
