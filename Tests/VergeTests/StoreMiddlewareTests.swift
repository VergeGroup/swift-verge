
import XCTest

final class StoreMiddlewareTests: XCTestCase {
    
  func testCommitHook() {
        
    let store = DemoStore()
    
    store.add(middleware: .unifiedMutation({ (state) in
      state.count += 1
    }))
    
    XCTAssertEqual(store.state.count, 0)
    
    store.commit {
      $0.count += 1
    }
    
    XCTAssertEqual(store.state.count, 2)
     
  }
  
}
