import Verge
import XCTest
import Atomics

final class StoreTaskTests: XCTestCase {

  func test() {
    
    let atomic = ManagedAtomic<Bool>.init(false)

    do {
      let r = atomic.compareExchange(expected: true, desired: true, ordering: .sequentiallyConsistent).exchanged
      print(r)
    }

    do {
      let r = atomic.compareExchange(expected: true, desired: false, ordering: .sequentiallyConsistent).exchanged
      print(r)
    }

    do {
      let r = atomic.compareExchange(expected: false, desired: true, ordering: .sequentiallyConsistent).exchanged
      print(r)
    }

  }

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
