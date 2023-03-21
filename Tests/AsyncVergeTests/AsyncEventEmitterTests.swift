import XCTest

import AsyncVerge

final class AsyncEventEmitterTests: XCTestCase {

  @MainActor
  func test_emit() async {

    let emitter = AsyncEventEmitter<Int>()

    var value: Int = 0

    await emitter.addEventHandler { event in
      value = event
    }

    await emitter.accept(1)

    XCTAssertEqual(value, 1)

  }
   
  @MainActor
  func test_emit_recursive() async {

    var events1: [Int] = []
    var events2: [Int] = []
    let emitter = AsyncEventEmitter<Int>()
    
    await emitter.addEventHandler { event in
      print("[1]", event)
      
      events1.append(event)

      if event == 1 {
        Task {
          await emitter.accept(2)
        }
      }

    }

    await emitter.addEventHandler { event in
      print("[2]", event)
      events2.append(event)
    }

    await emitter.accept(1)

    XCTAssertEqual(events1, [1, 2])
    XCTAssertEqual(events2, [1, 2])
  }

}
