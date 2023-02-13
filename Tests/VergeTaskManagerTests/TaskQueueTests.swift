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
}
