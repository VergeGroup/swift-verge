import Verge
import VergeTaskManager
import XCTest

@discardableResult
func dummyTask<V>(_ v: V, nanoseconds: UInt64) async -> V {
  try? await Task.sleep(nanoseconds: nanoseconds)
  return v
}

final class TaskManagerTests: XCTestCase {

  @MainActor
  func test_run_distinct_tasks() async {

    let manager = TaskManagerActor()

    let events: VergeConcurrency.UnfairLockAtomic<[String]> = .init([])

    await manager.batch {
      $0.task(key: .distinct(), mode: .dropCurrent) {
        await dummyTask("", nanoseconds: 1)
        events.modify { $0.append("1") }
      }
      $0.task(key: .distinct(), mode: .dropCurrent) {
        await dummyTask("", nanoseconds: 1)
        events.modify { $0.append("2") }
      }
      $0.task(key: .distinct(), mode: .dropCurrent) {
        await dummyTask("", nanoseconds: 1)
        events.modify { $0.append("3") }
      }
    }

    try? await Task.sleep(nanoseconds: 1_000_000)

    XCTAssertEqual(Set(events.value), Set(["1", "2", "3"]))

  }

  @MainActor
  func test_drop_current_task_in_key() async {

    let manager = TaskManagerActor()

    let events: VergeConcurrency.UnfairLockAtomic<[String]> = .init([])

    for i in (0..<10) {
      try? await Task.sleep(nanoseconds: 100_000_000)
      await manager.task(key: .init("request"), mode: .dropCurrent) {
        await dummyTask("", nanoseconds: 1_000_000_000)
        guard Task.isCancelled == false else { return }
        events.modify { $0.append("\(i)") }
      }
    }

    try? await Task.sleep(nanoseconds: 2_000_000_000)

    XCTAssertEqual(events.value, ["9"])
  }

  @MainActor
  func test_wait_current_task_in_key() async {

    let manager = TaskManagerActor()

    let events: VergeConcurrency.UnfairLockAtomic<[String]> = .init([])

    await manager.task(key: .init("request"), mode: .dropCurrent) {
      await dummyTask("", nanoseconds: 5_000_000)
      guard Task.isCancelled == false else { return }
      events.modify { $0.append("1") }
    }

    try? await Task.sleep(nanoseconds: 1_000)

    await manager.task(key: .init("request"), mode: .waitInCurrent) {
      await dummyTask("", nanoseconds: 5_000_000)
      guard Task.isCancelled == false else { return }
      events.modify { $0.append("2") }
    }

    try? await Task.sleep(nanoseconds: 1_000_000_000)

    XCTAssertEqual(events.value, ["1", "2"])
  }
}
