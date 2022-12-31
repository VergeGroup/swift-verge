import Foundation
import Verge
import XCTest

final class StateTypeTests: XCTestCase {

  func test_store() {

    let store = Store<State, Never>(initialState: .init())

    store.commit {
      $0.count = 1
    }
        
    XCTAssertEqual(store.state.count2, 1)
  }

  struct State: StateType {

    var count = 0
    var count2 = 0
    
    static func reduce(
      modifying: inout InoutRef<StateTypeTests.State>,
      current: Changes<StateTypeTests.State>
    ) {

      current.ifChanged(\.count) { _ in
        modifying.count2 += 1
      }
      
    }

  }

}
