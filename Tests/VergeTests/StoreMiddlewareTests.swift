
import XCTest

final class StoreMiddlewareTests: XCTestCase {
    
  func testCommitHook() {
        
    let store = DemoStore()
        
    store.add(middleware: .modify { @Sendable modifyingState, transaction, current in
      current.ifChanged(\.count).do { _ in
        modifyingState.count += 1
      }
    })
    
    store.add(middleware: .modify { @Sendable modifyingState, transaction, current in
      current.ifChanged(\.name).do { _ in
        modifyingState.count = 100
      }
    })
    
    XCTAssertEqual(store.state.count, 0)
    
    store.commit {
      $0.count += 1
    }
    
    XCTAssertEqual(store.state.count, 2)
    
    store.commit {
      $0.name = "A"
    }
     
    XCTAssertEqual(store.state.count, 100)
  }
  
}
