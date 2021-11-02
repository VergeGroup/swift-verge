import XCTest

import AsyncVerge

final class AsyncEventEmitterTests: XCTestCase {

  @MainActor
  func test_emit() async {

    let emitter = AsyncEventEmitter<Int>()

    var value: Int = 0

    await emitter.add { event in
      value = event
    }

    await emitter.accept(1)

    XCTAssertEqual(value, 1)

  }

  @MainActor
  func test_emit_recursive() async {

    let emitter = AsyncEventEmitter<Int>()

    await emitter.add { event in
      print("[1]", event)

      if event == 1 {
        Task {
          await emitter.accept(2)
        }
      }

    }

    await emitter.add { event in
      print("[2]", event)
    }

    await emitter.accept(1)

  }

}
