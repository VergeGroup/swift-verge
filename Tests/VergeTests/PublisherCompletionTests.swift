
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

    XCTAssertNil(weakStore)
    bag.forEach { $0.cancel() }
    XCTAssertNil(weakStore)
  }

  func testActivityPublisherCompletion_deallocated() {

    var bag = Set<AnyCancellable>()

    var store: DemoStore? = DemoStore()
    weak var weakStore: DemoStore? = store

    var strongRef: Ref? = Ref()
    weak var weakRef = strongRef

    let e = expectation(description: "completion")

    store!.activityPublisher()
      .sink(
        receiveCompletion: { _ in
          print("")
          e.fulfill()
        },
        receiveValue: { _ in
        withExtendedLifetime(strongRef) {}
      })
      .store(in: &bag)

    strongRef = nil
    store = nil

    XCTAssertNil(weakStore)

    XCTAssertNil(weakRef)

    wait(for: [e], timeout: 10)
  }

  class Ref {}
}
