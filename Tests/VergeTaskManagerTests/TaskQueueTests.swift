
import VergeTaskManager
import XCTest

final class TaskQueueTests: XCTestCase {
  
  @MainActor
  func testQueue() async {
    
    let queue = TaskQueue()
    
    let exp = expectation(description: "")
        
    queue.addTask {
      try! await Task.sleep(nanoseconds: 1)
    }
    
    queue.addTask {
      try! await Task.sleep(nanoseconds: 1)
      exp.fulfill()
    }
    
    wait(for: [exp], timeout: 1)
    
  }
  
  @MainActor
  func testCancel() async {
    
    let queue = TaskQueue()
    
    queue.addTask {
      try! await Task.sleep(nanoseconds: 1_000)
    }
    
    queue.addTask {
      try! await Task.sleep(nanoseconds: 1_000)
//      XCTFail()
    }
    
    await queue.waitUntilAllItemProcessed()
    
    print("done")
  }
}
