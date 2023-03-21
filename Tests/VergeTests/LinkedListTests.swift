
import XCTest
@testable import Verge

class LinkedListTests: XCTestCase {

  func testAppend() {
    var list = LinkedList<Int>()

    XCTAssertTrue(list.isEmpty)

    list.append(1)
    list.append(2)
    list.append(3)

    XCTAssertFalse(list.isEmpty)
  }

  func testRemoveFirst() {
    var list = LinkedList<Int>()
    list.append(1)
    list.append(2)
    list.append(3)

    XCTAssertEqual(list.removeFirst(), 1)
    XCTAssertEqual(list.removeFirst(), 2)
    XCTAssertEqual(list.removeFirst(), 3)
    XCTAssertNil(list.removeFirst())
    XCTAssertTrue(list.isEmpty)
  }

  func testCopyOnWrite() {
    var list1 = LinkedList<Int>()
    list1.append(1)
    list1.append(2)

    var list2 = list1
    list1.append(3)
    list2.append(4)

    XCTAssertEqual(list1.removeFirst(), 1)
    XCTAssertEqual(list1.removeFirst(), 2)
    XCTAssertEqual(list1.removeFirst(), 3)

    XCTAssertEqual(list2.removeFirst(), 1)
    XCTAssertEqual(list2.removeFirst(), 2)
    XCTAssertEqual(list2.removeFirst(), 4)
  }

  func testCopyOnWriteIndependence() {
    var list1 = LinkedList<Int>()
    list1.append(1)
    list1.append(2)
    list1.append(3)

    var list2 = list1

    // Modify list1
    list1.removeFirst()
    list1.append(4)

    // Verify list1 and list2 have independent states
    XCTAssertEqual(list1.removeFirst(), 2)
    XCTAssertEqual(list1.removeFirst(), 3)
    XCTAssertEqual(list1.removeFirst(), 4)

    XCTAssertEqual(list2.removeFirst(), 1)
    XCTAssertEqual(list2.removeFirst(), 2)
    XCTAssertEqual(list2.removeFirst(), 3)
    XCTAssertNil(list2.removeFirst())
  }
}
