import XCTest
import Verge

final class WritingStateTests: XCTestCase {

  @Writing
  struct MyState {

    var age: Int = 18
    var name: String

    @ReferenceEdge var edge: Int = 0

    var computedName: String {
      "Mr. " + name
    }

  }

  func testObserve() {

    var myState = MyState(name: "")

    let r = MyState.modify(source: &myState) {
      $0.name = "Hello"
    }

    XCTAssert(r.modifiedIdentifiers.contains("name"))

  }

}
