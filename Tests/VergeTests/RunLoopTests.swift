import XCTest
@testable import Verge

final class RunLoopTests: XCTestCase {

  func test_performance_adding() {

    measure {
      for _ in 0..<1000 {
        RunLoopActivityObserver.addObserver(acitivity: .beforeWaiting, in: .main) {
        }
      }
    }

  }

}
