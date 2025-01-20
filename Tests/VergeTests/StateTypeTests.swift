import Foundation
import Verge
import XCTest

final class StateTypeTests: XCTestCase {
  
  func test_init() {
    
    let store = Store<State, Never>(initialState: .init())
    
    XCTAssertEqual(store.state.count2, 1)
    
  }

  func test_store() {

    let store = Store<State, Never>(initialState: .init())

    store.commit {
      $0.count = 1
    }
        
    XCTAssertEqual(store.state.count2, 2)
    
    store.commit {
      $0.name = "a"
    }
    
    XCTAssertEqual(store.state.count2, 2)
  }

  struct State: StateType {

    var name = ""
    var count = 0
    var count2 = 0
    
    static func reduce(
      modifying: inout InoutRef<StateTypeTests.State>,
      current: Changes<StateTypeTests.State>
    ) {

      current.ifChanged(\.count).do { _ in
        modifying.count2 += 1
      }
      
    }

  }

}
