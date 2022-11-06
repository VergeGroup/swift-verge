
import XCTest
import VergeTaskManager

final class TaskTests: XCTestCase {
  
  func testCancel() async {
    
    let manager = TaskManager()
    
    let id = TaskManager.TaskKey.distinct()
    
    let firstTask = expectation(description: "cancelled")
    let nextTask = expectation(description: "cancelled")
    
    manager.task(id: id, mode: .dropCurrent) {
      await withTaskCancellationHandler {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
      } onCancel: {
        firstTask.fulfill()
      }
    }
    
    XCTAssertEqual(manager.count, 1)
    
    manager.task(id: id, mode: .dropCurrent) {
      await withTaskCancellationHandler {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        nextTask.fulfill()
      } onCancel: {
        XCTFail()
      }
    }
    
    XCTAssertEqual(manager.count, 1)
        
    wait(for: [firstTask], timeout: 2)
    
    XCTAssertEqual(manager.count, 1)
    
    wait(for: [nextTask], timeout: 2)
    
    XCTAssertEqual(manager.count, 0)
  }
  
  func testCancelAll() {
    
    let manager = TaskManager()
    
    let firstTask = expectation(description: "cancelled")
    
    manager.task(id: .distinct(), mode: .dropCurrent) {
      await withTaskCancellationHandler {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
      } onCancel: {
        firstTask.fulfill()
      }
    }
    
    manager.cancelAll()
    XCTAssertEqual(manager.count, 0)
    
    wait(for: [firstTask], timeout: 2)
    
  }
  
}
