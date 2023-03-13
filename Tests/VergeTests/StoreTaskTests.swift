import Verge
import XCTest

final class StoreTaskTests: XCTestCase {

  @MainActor
  func testActorContext_onMainActor() async throws {

    let store = DemoStore()

    try await store.task {
      XCTAssertTrue(Thread.isMainThread)
    }
    .value

    try await store.taskDetached {
      XCTAssertFalse(Thread.isMainThread)
    }
    .value
  }

  func testActorContext() async throws {

    let store = DemoStore()

    try await store.task {
      XCTAssertFalse(Thread.isMainThread)
    }
    .value

    try await store.taskDetached {
      XCTAssertFalse(Thread.isMainThread)
    }
    .value
  }
}
