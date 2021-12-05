import XCTest

final class ConcurrencyFacts: XCTestCase {

  func test_non_async() {
    XCTAssertEqual(Thread.current, .main)
  }

  func test_async() async {
    XCTAssertNotEqual(Thread.current, .main)
  }

  func test_task() {

    let exp = expectation(description: "Done")

    XCTAssertEqual(Thread.current, .main)

    Task {

      XCTAssertNotEqual(Thread.current, .main)

      exp.fulfill()
    }

    wait(for: [exp], timeout: 10)
  }

  func test_task_detached() {

    let exp = expectation(description: "Done")

    XCTAssertEqual(Thread.current, .main)

    Task.detached {

      XCTAssertNotEqual(Thread.current, .main)

      exp.fulfill()
    }

    wait(for: [exp], timeout: 10)

  }

  func test_class() async {

    final class Object {

      @MainActor
      func entry() async {

        chain3()

        _ = await Task.init {

          chain3()

          XCTAssertEqual(Thread.current, .main)

          await run_async {
            XCTAssertEqual(Thread.current, .main)
          }

          run_not_async_mainActor {
            XCTAssertEqual(Thread.current, .main)
          }

          run_not_async_noActor {
            XCTAssertEqual(Thread.current, .main)
          }
        }
        .result

        //        _ = await Task.detached { [self] in
        //          XCTAssertNotEqual(Thread.current, .main)
        //
        //          await run_async {
        //            XCTAssertNotEqual(Thread.current, .main)
        //          }
        //
        //          await run_not_async_mainActor {
        //            XCTAssertEqual(Thread.current, .main)
        //          }
        //
        //          run_not_async_noActor {
        //            XCTAssertNotEqual(Thread.current, .main)
        //          }
        //        }
        //        .result

        await chain()
      }

      func chain() async {
        await run_not_async_mainActor {

        }
      }

      @MainActor
      func chain2() async {
        run_not_async_mainActor {

        }
      }

      @MainActor
      func chain3() {
      }

      func run_async(closure: () -> Void) async {
        closure()
      }

      @MainActor
      func run_not_async_mainActor(closure: () -> Void) {
        closure()
      }

      func run_not_async_noActor(closure: () -> Void) {
        closure()
      }

    }

    let object = Object()
    await object.entry()

    print("finish")

  }

  @MainActor
  func test_reentrant() async {

    actor MyActor {

      var values: [String] = []

      func operation(asyncSleep: UInt64, label: String) async {

        values.append("In: \(label)")
        try! await Task.sleep(nanoseconds: UInt64(asyncSleep) * 1_000_000_000)
        values.append("Out: \(label)")

      }

    }

    let actor = MyActor()

    await withTaskGroup(of: Void.self) { group in

      group.addTask {
        await actor.operation(asyncSleep: 3, label: "1")
      }

      group.addTask {
        await actor.operation(asyncSleep: 1, label: "2")
      }

    }

    print(await actor.values)

  }

  @MainActor
  func test_queueing() async {

    actor MyActor {

      var values: [String] = []

      init() {

      }

      func hoge() -> [String] {
        values
      }

      func operation(asyncSleep: UInt64, label: String) async {

        await Task.init {
          print(values)
          print("In: \(label)", Thread.current)
          try! await Task.sleep(nanoseconds: UInt64(asyncSleep) * 1_000_000_000)
          print("Out: \(label)", Thread.current)
        }
        .result
      }

      private func drain() {

      }

    }

    let actor = MyActor()

    await withTaskGroup(of: Void.self) { group in

      group.addTask {
        await actor.operation(asyncSleep: 3, label: "1")
      }

      group.addTask {
        await actor.operation(asyncSleep: 1, label: "2")
      }

    }

    print(await actor.values)

  }

}


final class ActorFacts: XCTestCase {

  actor MyActor {

    var results: [String] = []

    func run(value: Int) {
      if value == 1 {
        run(value: 2)
      }
      process(value: value)
    }

    @discardableResult
    func run_task(value: Int) -> Task<Void, Never> {
      Task {
        if value == 1 {
          run_task(value: 2)
        }
        process(value: value)
      }
    }

    private func process(value: Any) {
      let value = "✅ \(value)"
      results.append(value)
      print(results)
    }

  }

  @MainActor
  func test_task() async {

    let actor = MyActor()

    await actor.run_task(value: 1)

  }

  @MainActor
  func test_no_task() async {

    let actor = MyActor()

    await actor.run(value: 1)

  }

}
