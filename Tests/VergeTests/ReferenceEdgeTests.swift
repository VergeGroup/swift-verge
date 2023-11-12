
import XCTest
import Verge

final class FragmentTests: XCTestCase {

  struct State {
    var name: String = ""
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

    XCTAssertNotEqual(state.$number._storagePointer, anotherState.$number._storagePointer)
  }

  func testReference() {

    var state = State()

    state.number += 1

    state.name = "A"

    var state2 = state
    state2.name = "B"

    XCTAssert(state.$number._storagePointer == state2.$number._storagePointer)

  }

  func testCast() {

    let source = ReferenceEdge<State?>(wrappedValue: State())

    var binded = unsafeBitCast(source, to: ReferenceEdge<State>.self)

    print(binded.name)

    binded.name = "hiroshi"

    XCTAssertEqual(binded.name, "hiroshi")

  }

}

