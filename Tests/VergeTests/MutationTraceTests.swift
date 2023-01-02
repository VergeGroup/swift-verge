
import XCTest

import Verge

@MainActor
final class MutationTraceTests: XCTestCase {
  
  func testOneCommit() {
    
    let store = DemoStore()
    
    store.commit("MyCommit") {
      $0.count += 1
    }
    
    let state = store.state
    
    XCTAssertEqual(state.traces.count, 1)
    XCTAssertEqual(state.traces.first!.name, "MyCommit")
  }
  
  func testDerived() {
    
    let store = DemoStore()
    
    let derived = store
      .derived(.map(\.count), queue: .passthrough)
    
    store.commit("From_Store") {
      $0.count += 1
    }
    
    let value = derived.value
    
    XCTAssertEqual(value.traces.count, 2)
    
  }
  
}
