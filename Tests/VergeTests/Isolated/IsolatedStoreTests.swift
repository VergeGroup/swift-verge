
import Verge
import XCTest

final class MainActorIsolatedStoreTests: XCTestCase {

  @MainActor
  func test_mainActorStore_in_mainActor() {

    let store = MainActorStore<_, Never>(initialState: DemoState())

    XCTAssertEqual(store.state.count, 0)

    store.commit {
      $0.count = 1
    }

    XCTAssertEqual(store.state.count, 1)

  }

  nonisolated func test_mainActorStore_in_nonisolated() async {

    let store = await MainActorStore<_, Never>(initialState: DemoState())

    do {
      let count = await store.state.count
      XCTAssertEqual(count, 0)
    }

    await store.commit {
      $0.count = 1
    }

    do {
      let count = await store.state.count
      XCTAssertEqual(count, 1)
    }

  }

}

final class ActorIsolatedStoreTests: XCTestCase {

  @MainActor
  func test_asyncStore_in_mainActor() async {

    let store = AsyncStore<_, Never>(initialState: DemoState())

    XCTAssertEqual(store.state.count, 0)

    await store.backgroundCommit {
      $0.count = 1
    }

    XCTAssertEqual(store.state.count, 1)

  }

  nonisolated func test_mainActorStore_in_nonisolated() async {

    let store = AsyncStore<_, Never>(initialState: DemoState())

    XCTAssertEqual(store.state.count, 0)

    await store.backgroundCommit {
      $0.count = 1
    }

    XCTAssertEqual(store.state.count, 1)

  }

}
