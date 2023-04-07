import XCTest
import VergeTaskManager

final class TaskKeyTests: XCTestCase {

  func testBase() {

    enum LocalKey: TaskKeyType {}
    enum LocalKey2: TaskKeyType {}

    let key = TaskKey(LocalKey.self)
    let key2 = TaskKey(LocalKey2.self)

    XCTAssertNotEqual(key, key2)
    XCTAssertEqual(key, key)
  }

  func testCombined() {

    enum LocalKey: TaskKeyType {}

    let key = TaskKey(LocalKey.self)

    XCTAssertEqual(key, key.combined(.init(LocalKey.self)))
    XCTAssertNotEqual(key, key.combined("A"))

  }

}
