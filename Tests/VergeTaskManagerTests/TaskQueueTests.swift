import Verge
import VergeTaskManager
import XCTest

final class TaskQueueTests: XCTestCase {

  @MainActor
  func testQueue() async {

    let queue = TaskQueueActor()

    let events = VergeConcurrency.UnfairLockAtomic<[String]>([])

    let ref_1 = await queue.addTask { @MainActor in
      try! await Task.sleep(nanoseconds: 1)
      events.modify { $0.append("Completed-1") }
    }

    Task {
      _ = try await ref_1.value
      events.modify { $0.append("Completed-Ref-1") }
    }

    let ref_2 = await queue.addTask { @MainActor in
      try! await Task.sleep(nanoseconds: 1)
      events.modify { $0.append("Completed-2") }
    }

    Task {
      _ = try await ref_2.value
      events.modify { $0.append("Completed-Ref-2") }
    }

    await queue.waitUntilAllItemProcessed()

    try? await Task.sleep(nanoseconds: 1_000_000)

    XCTAssertEqual(
      Set(events.value),
      Set([
        "Completed-1",
        "Completed-Ref-1",
        "Completed-2",
        "Completed-Ref-2",
      ])
    )

  }

  @MainActor
  func testCancel() async {

    let queue = TaskQueueActor()

    await queue.addTask {
      print("1")
      try? await Task.sleep(nanoseconds: 1_000_000)
    }

    await queue.addTask {
      print("2", Task.isCancelled)
      try? await Task.sleep(nanoseconds: 1_000)
      guard Task.isCancelled == false else { return }
      XCTFail()
    }

    await queue.cancelAllTasks()

    await queue.waitUntilAllItemProcessed()

    print("done")
  }
  
  func test_cancel_release_of_resources() {
    
    let e = expectation(description: "A")
    e.assertForOverFulfill = true
    e.expectedFulfillmentCount = 3
    let events = Store<[String], Never>.init(initialState: .init())
            
    Task {
            
      func add(_ label: String) async {
        let resource = VergeAnyCancellable {
          print("Deinit", label)
          e.fulfill()
          events.commit { $0.wrapped.append("Deinit:\(label)") }
        }
        let ref = await queue.addTask(label: label) {
          await networking(token: "1")
        }
        Task {
          let _ = try await ref.value
          withExtendedLifetime(resource) {}
        }
      }
    
      
      let queue = TaskQueueActor()
      
      await add("1")
      try? await Task.sleep(nanoseconds: 1_000_000_00)
      await add("2")
      try? await Task.sleep(nanoseconds: 1_000_000_00)
      await add("3")
            
      try? await Task.sleep(nanoseconds: 1_000_000_00)
      
      await queue.cancelAllTasks()
               
    }
    
    wait(for: [e], timeout: 10)
        
  }
}

private func networking(token: String) async {
  print("Start", token)
  try? await Task.sleep(nanoseconds: 2_000_000_000)
  if Task.isCancelled {
    print("Cancelled", token)
  } else {
    print("Done", token)
  }
}
