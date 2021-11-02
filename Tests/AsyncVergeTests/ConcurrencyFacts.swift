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

        _ = await Task.init {
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

}
