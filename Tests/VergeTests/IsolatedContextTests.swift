
import XCTest

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
    
    _ = store.sinkState(queue: .main) { changes in
      isInMain()
    }
    
    _ = store.sinkState(queue: .mainIsolated()) { changes in
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
    
    var receivedState: DemoStore.State?
    
    let sub = store.sinkState { changes in
      receivedState = changes.primitive
    }
    
    store.commit {
      $0.count = 100
    }
    
    XCTAssertEqual(receivedState?.count, 100)
    
    withExtendedLifetime(sub, {})
  }
  
  
}
