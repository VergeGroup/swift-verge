
import XCTest
import VergeTaskManager

final class TaskTests: XCTestCase {
  
  func testCancel() async {
    
    let manager = TaskManager()
    
    let id = TaskManager.TaskID.distinct()
    let exp = expectation(description: "cancelled")
    
    await manager.task(id: id, mode: .dropCurrent) {
      await withTaskCancellationHandler {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
      } onCancel: {
        exp.fulfill()
      }
    }
    
    await manager.task(id: id, mode: .dropCurrent) {
      await withTaskCancellationHandler {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
      } onCancel: {
        
      }
    }
        
    wait(for: [exp], timeout: 2)
  }
  
}
