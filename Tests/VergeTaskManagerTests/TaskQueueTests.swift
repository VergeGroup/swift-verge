
import VergeTaskManager
import XCTest

final class TaskQueueTests: XCTestCase {
  
  @MainActor
  func testQueue() async {
    
    let queue = TaskQueueActor()
    
    let exp = expectation(description: "")
        
    await queue.addTask {
      try! await Task.sleep(nanoseconds: 1)
    }
    
    await queue.addTask {
      try! await Task.sleep(nanoseconds: 1)
      exp.fulfill()
    }
    
    wait(for: [exp], timeout: 1)
    
  }
  
  @MainActor
  func testCancel() async {
    
    let queue = TaskQueueActor()
    
    let exp_1 = expectation(description: "1")
    
    await queue.addTask {
      print("1")
      try! await Task.sleep(nanoseconds: 1_000)
      exp_1.fulfill()
    }
    
    await queue.addTask {
      print("2")
      try! await Task.sleep(nanoseconds: 1_000)
      XCTFail()
    }
    
    await queue.cancelAllTasks()
    
    await queue.waitUntilAllItemProcessed()
    
    wait(for: [exp_1], timeout: 12)
    
    print("done")
  }
}
