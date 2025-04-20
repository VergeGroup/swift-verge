
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
      .sink(
        receiveCompletion: { _ in
          XCTFail()
        },
        receiveValue: { _ in }
      )
      .store(in: &bag)

    XCTAssertNotNil(weakStore)

    store = nil

    XCTAssertNil(weakStore)

  }

  func testActivityPublisherCompletion1() {

    var bag = Set<AnyCancellable>()

    var store: DemoStore? = DemoStore()
    weak var weakStore: DemoStore? = store

    store?
      .activityPublisher()
      .sink(
        receiveCompletion: { _ in
          XCTFail()
        },
        receiveValue: { _ in
          
        }
      )
      .store(in: &bag)

    XCTAssertNotNil(weakStore)

    store = nil

    XCTAssertNil(weakStore)
    bag.forEach { $0.cancel() }
    XCTAssertNil(weakStore)

  }

  func testActivityPublisherCompletion2() {

    var bag = Set<AnyCancellable>()

    var store: DemoStore? = DemoStore()
    weak var weakStore: DemoStore? = store

    store!.activityPublisher()
      .sink(
        receiveCompletion: { _ in
          XCTFail("It should not be called, as the subscription was canceled before publishing completion.")
        },
        receiveValue: { [store] _ in
          withExtendedLifetime(store) {}
        }
      )
      .store(in: &bag)

    XCTAssertNotNil(weakStore)

    store = nil

    XCTAssertNotNil(weakStore)
    bag.forEach { $0.cancel() }
    XCTAssertNil(weakStore)

  }

  func testActivityPublisherCompletion_deallocated() {

    var bag = Set<AnyCancellable>()

    var store: DemoStore? = DemoStore()
    weak var weakStore: DemoStore? = store

    var strongRef: Ref? = Ref()
    weak var weakRef = strongRef

    store!.activityPublisher()
      .sink(
        receiveCompletion: { _ in
          XCTFail()
        },
        receiveValue: { _ in
          print("")
          withExtendedLifetime(strongRef) {}
        }
      )
      .store(in: &bag)

    strongRef = nil
    store = nil

    XCTAssertNil(weakStore)

    XCTAssertNil(weakRef)

  }

  func testDerived_publisher_retains_derived() {

    var c: AnyCancellable?

    let ref = withReference(DemoStore())

    let derivedRef = withReference(ref.value!.derived(.map(\.count)))

    c = derivedRef.value!
      .statePublisher()
      .sink(
        receiveCompletion: { _ in
          XCTFail()
        },
        receiveValue: { _ in

        }
      )


    derivedRef.release()

    XCTAssertNotNil(derivedRef.value)

    c?.cancel()

    XCTAssertNil(derivedRef.value)

  }

  func testDerived_stream_stops_on_store_deallocated() async {

    var c: AnyCancellable?

    let storeRef = withReference(DemoStore())

    let derivedRef = withReference(storeRef.value!.derived(.map(\.count)))

    storeRef.release()

    await Task.yield()

    XCTAssertNil(storeRef.value)

    c = derivedRef.value!
      .statePublisher()
      .sink(
        receiveCompletion: { _ in
          XCTFail()
        },
        receiveValue: { _ in
        }
      )

    derivedRef.release()

    await Task.yield()
    
    // still not nil as the subscription is still on going.
    XCTAssertNotNil(derivedRef.value)

    XCTAssertNil(storeRef.value)
    
    withExtendedLifetime(c, {})
    
    c?.cancel()
    
    XCTAssertNil(derivedRef.value)

  }

  class Ref {}
}

final class Reference<T: AnyObject>: @unchecked Sendable {

  weak var value: T?
  private var strong: T?

  init(_ object: T){
    self.value = object
    self.strong = object
  }

  func release() {
    strong = nil
  }

}

func withReference<T: AnyObject>(_ object: T) -> Reference<T> {
  return .init(object)
}
