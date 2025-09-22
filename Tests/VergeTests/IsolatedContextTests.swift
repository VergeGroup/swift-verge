
import XCTest
import os.lock

@MainActor
fileprivate func isInMain() {}

final class IsolatedContextTests: XCTestCase {
  
  func testMainActorSubscription() {
    
    Task { @MainActor in
      isInMain()
    }
    
    let store = DemoStore()
    
    _ = store.sinkState { changes in
      isInMain()
    }
    
    _ = store.sinkState(queue: .main) { @MainActor changes in
      isInMain()
    }
    
    _ = store.sinkState(queue: .mainIsolated()) { @MainActor changes in
      isInMain()
    }
    
    _ = store.sinkState(queue: .asyncSerialBackground) { changes in
      Task { @MainActor in
        isInMain()
      }
    }
    
  }
  
  func testMainActorSubscription_sink() {
    
    // don't add `@MainActor` to make non-isolated-context
    
    assert(Thread.isMainThread)
        
    let store = DemoStore()
    
    let receivedState: OSAllocatedUnfairLock<DemoStore.State?> = .init(initialState: nil)
    
    let sub = store.sinkState { changes in
      receivedState.withLock {
        $0 = changes.primitive
      }
    }
    
    store.commit {
      $0.count = 100
    }
    
    XCTAssertEqual(receivedState.withLock { $0?.count }, 100)
    
    withExtendedLifetime(sub, {})
  }
  
  
}
