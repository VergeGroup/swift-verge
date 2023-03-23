import Verge
import XCTest

@MainActor
fileprivate func UI() {

}

final class StoreSinkTests: XCTestCase {

  func testMainActorSubscription() {

    let store = DemoStore()

    _ = store.sinkState { _ in
      UI()
    }

    _ = store.sinkState(queue: .main) { @MainActor _ in
      UI()
    }

  }

  func testNonActorSubscription() {

    let store = DemoStore()

    _ = store.sinkState(queue: .passthrough) { _ in
      Task {
        await UI()
      }
    }
  }
}
