
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
      isInMain()
    }
    
  }
  
  
}
