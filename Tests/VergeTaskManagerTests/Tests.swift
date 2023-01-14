
import XCTest
import VergeTaskManager

final class TaskTests: XCTestCase {
  
  @MainActor
  func testCancel() async {
    
    let manager = TaskManagerActor()
    
    let key = TaskKey.distinct()
    
    let firstTask = expectation(description: "cancelled")
    let nextTask = expectation(description: "cancelled")
    
    await manager.task(key: key, mode: .dropCurrent) {
      await withTaskCancellationHandler {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
      } onCancel: {
        firstTask.fulfill()
      }
    }
    
    do {
      let count = await manager.count
      XCTAssertEqual(count, 1)
    }
    
    await manager.task(key: key, mode: .dropCurrent) {
      await withTaskCancellationHandler {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        nextTask.fulfill()
      } onCancel: {
        XCTFail()
      }
    }
    
    do {
      let count = await manager.count
      XCTAssertEqual(count, 1)
    }
        
    wait(for: [firstTask], timeout: 2)
    
    do {
      let count = await manager.count
      XCTAssertEqual(count, 1)
    }
    
    wait(for: [nextTask], timeout: 2)
    
    do {
      let count = await manager.count
      XCTAssertEqual(count, 0)
    }
  }

  @MainActor
  func testCancelAll() async {
    
    let manager = TaskManagerActor()
    
    let firstTask = expectation(description: "cancelled")
    
    await manager.task(key: .distinct(), mode: .dropCurrent) {
      await withTaskCancellationHandler {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
      } onCancel: {
        firstTask.fulfill()
      }
    }
    
    await manager.cancelAll()
    
    do {
      let count = await manager.count
      XCTAssertEqual(count, 0)
    }
    
    wait(for: [firstTask], timeout: 2)
    
  }
  
}
