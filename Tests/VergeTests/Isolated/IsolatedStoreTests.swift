
import Verge
import XCTest

final class MainActorIsolatedStoreTests: XCTestCase {

  typealias TestStore = MainActorStore<DemoState, Never>

  @MainActor
  func test_mainActorStore_in_mainActor() {

    let store = TestStore(initialState: .init())

    XCTAssertEqual(store.state.count, 0)

    store.commit {
      $0.count = 1
    }

    XCTAssertEqual(store.state.count, 1)

  }

  nonisolated func test_mainActorStore_in_nonisolated() async {

    let store = TestStore(initialState: .init())

    do {
      let count = store.state.count
      XCTAssertEqual(count, 0)
    }

    await store.commit {
      $0.count = 1
    }

    do {
      let count = store.state.count
      XCTAssertEqual(count, 1)
    }

  }

  @MainActor
  func test_make_derived() {

    let store = TestStore(initialState: .init())

    let derived = store.derived(.select(\.count))

    XCTAssertEqual(derived.state.primitive, 0)

    store.commit {
      $0.count = 1
    }

    XCTAssertEqual(derived.state.primitive, 1)

  }

  final class Driver: MainActorStoreDriverType {

    typealias Store = TestStore

    nonisolated var scope: WritableKeyPath<DemoState, DemoState.Inner> {
      \.inner
    }

    let store: MainActorIsolatedStoreTests.TestStore

    nonisolated init(store: MainActorIsolatedStoreTests.TestStore) {
      self.store = store
    }

  }

  func test_driver() async {

    let store = TestStore(initialState: .init())

    let driver = Driver(store: store)

    await driver.commit {
      $0.name = "Hiroshi"
    }

    let after = await driver.state

    XCTAssertEqual(after.name, "Hiroshi")

  }

}

final class ViewModelTests: XCTestCase {

  @MainActor
  final class ViewModel: MainActorStoreDriverType {

    struct State: StateType {
      static func reduce(
        modifying: inout Self,
        current: Changes<Self>,
        transaction: inout Transaction
      ) {}
    }

    let store: MainActorStore<State, Never> = .init(initialState: .init())

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
