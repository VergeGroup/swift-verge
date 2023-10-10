
import XCTest
import Verge

final class FragmentTests: XCTestCase {

  struct State {
    @ReferenceEdge var number = 0
  }

  func testFragment() {

    var state = State()
    XCTAssertEqual(state.number, 0)

    state.number += 1

    XCTAssertEqual(state.number, 1)
  }

  func testFragmentWithCopy() {

    let state = State()
    XCTAssertEqual(state.number, 0)

    var anotherState = state
    anotherState.number += 1

    XCTAssertEqual(anotherState.number, 1)
  }

}

