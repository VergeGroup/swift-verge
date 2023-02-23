
import Foundation
import Combine
import Verge
import XCTest

final class SubjectCompletionTests: XCTestCase {

  func testStatePublisherCompletion1() {

    var bag = Set<AnyCancellable>()

    var store: DemoStore? = DemoStore()
    weak var weakStore: DemoStore? = store

    store?.statePublisher()
      .sink(receiveValue: { _ in })
      .store(in: &bag)

    XCTAssertNotNil(weakStore)

    store = nil

    XCTAssertNotNil(weakStore)
    bag.forEach { $0.cancel() }
    XCTAssertNil(weakStore)
  }

  func testActivityPublisherCompletion1() {

    var bag = Set<AnyCancellable>()

    var store: DemoStore? = DemoStore()
    weak var weakStore: DemoStore? = store

    store?.activityPublisher()
      .sink(receiveValue: { _ in })
      .store(in: &bag)

    XCTAssertNotNil(weakStore)

    store = nil

    XCTAssertNotNil(weakStore)
    bag.forEach { $0.cancel() }
    XCTAssertNil(weakStore)
  }
}
