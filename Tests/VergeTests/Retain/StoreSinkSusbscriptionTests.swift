import Verge
import XCTest
import Atomics

final class StoreSinkSubscriptionTests: XCTestCase {

  func test_Store_sinkState_stops_on_store_deallocated() {

    let storeRef = withReference(DemoStore())
    let resourceRef = withReference(Resource())

    storeRef.value!
      .sinkState { [ref = resourceRef.value!] _ in

        withExtendedLifetime(ref) {}
      }
      .storeWhileSourceActive()

    resourceRef.release()

    XCTAssertNotNil(storeRef.value)
    XCTAssertNotNil(resourceRef.value)

    storeRef.release()

    XCTAssertNil(storeRef.value)
    XCTAssertNil(resourceRef.value)

  }

  func test_Store_sinkState_canceled_by_others() {

    var cancellable: StoreStateSubscription?

    let storeRef = withReference(DemoStore())
    let resourceRef = withReference(Resource())

    cancellable = storeRef.value!
      .sinkState { [ref = resourceRef.value!] _ in

        withExtendedLifetime(ref) {}
      }
      .storeWhileSourceActive()

    resourceRef.release()

    XCTAssertNotNil(storeRef.value)
    XCTAssertNotNil(resourceRef.value)

    cancellable?.cancel()

    XCTAssertNotNil(storeRef.value)
    XCTAssertNil(resourceRef.value)

  }

  func test_Store_sinkActivity_stops_on_store_deallocated() {

    let storeRef = withReference(DemoStore())
    let resourceRef = withReference(Resource())

    storeRef.value!
      .sinkActivity { [ref = resourceRef.value!] _ in

        withExtendedLifetime(ref) {}
      }
      .storeWhileSourceActive()

    resourceRef.release()

    XCTAssertNotNil(storeRef.value)
    XCTAssertNotNil(resourceRef.value)

    storeRef.release()

    XCTAssertNil(storeRef.value)
    XCTAssertNil(resourceRef.value)

  }

  func test_Derived_lifeCycle_with_source() {

    let storeRef = withReference(DemoStore())
    let resourceRef = withReference(Resource())
    let derivedRef = withReference(storeRef.value!.derived(.select(\.count)))

    derivedRef.value!
      .sinkState { [ref = resourceRef.value!] _ in

        withExtendedLifetime(ref) {}
      }
      .storeWhileSourceActive()

    resourceRef.release()

    XCTAssertNotNil(storeRef.value)
    XCTAssertNotNil(resourceRef.value)

    storeRef.release()

    XCTAssertNil(storeRef.value)
    XCTAssertNil(resourceRef.value)

  }

  func test_Derived_lifeCycle_with_source_release_store_earlier() {

    let storeRef = withReference(DemoStore())
    let resourceRef = withReference(Resource())

    // make derived
    let derivedRef = withReference(storeRef.value!.derived(.select(\.count)))

    // start subscribe
    derivedRef.value!
      .sinkState { [ref = resourceRef.value!] _ in

        withExtendedLifetime(ref) {}
      }
      .storeWhileSourceActive()

    // make the resource is captured only from the closure
    resourceRef.release()
    XCTAssertNotNil(resourceRef.value)

    // release store earlier than stop derived
    storeRef.release()
    // should be nil because derived won't retain store as upstream
    XCTAssertNil(storeRef.value)

    // released all resouces
    XCTAssertNil(resourceRef.value)

  }

  func testCompare() {
    let wasInvalidated = Atomics.ManagedAtomic(false)

    XCTAssertTrue(wasInvalidated.compareExchange(expected: false, desired: true, ordering: .relaxed).exchanged)
    XCTAssertFalse(wasInvalidated.compareExchange(expected: false, desired: true, ordering: .relaxed).exchanged)
  }

  /**
   Store won't retain the Derived
   */
  func testRelease() {

    let wrapper = DemoStore()
    let ref = withReference(wrapper.derived(.map { @Sendable in $0.count }, queue: .passthrough))
    ref.release()
    XCTAssertNil(ref.value)

  }

  func testRetain() {

    let store = DemoStore()

    let derivedRef = withReference(store.derived(.map { @Sendable in $0.count }, queue: .passthrough))

    let expectation = XCTestExpectation(description: "receive changes")
    expectation.expectedFulfillmentCount = 1
    expectation.assertForOverFulfill = true

    let subscription = derivedRef
      .value!
      .sinkState(
        dropsFirst: true,
        queue: .passthrough
      ) { (changes) in
        expectation.fulfill()
      }

    XCTAssertNotNil(derivedRef.value)

    derivedRef.release()

    XCTAssertNotNil(derivedRef.value, "as still subscribing")

    store.commit { _ in }

    store.commit { $0.count += 1 }

    subscription.cancel()

    XCTAssertNil(derivedRef.value)

    wait(for: [expectation], timeout: 1)

  }

  func test_derived_chain() {

    let wrapper = DemoStore()

    var baseSlice: Derived<Int>! = wrapper.derived(.map { @Sendable in $0.count }, queue: .passthrough)

    weak var weakBaseSlice = baseSlice

    var slice: Derived<Int>! = baseSlice.derived(.map { @Sendable in $0.self }, queue: .passthrough)

    baseSlice = nil

    weak var weakSlice = slice

    XCTAssertEqual(slice.state.primitive, 0)
    XCTAssertEqual(slice.state.version, 0)
    XCTAssertEqual(slice.state.hasChanges(\.self), true)
    XCTAssertNotNil(weakBaseSlice)

    wrapper.increment()

    XCTAssertEqual(slice.state.primitive, 1)
    XCTAssertEqual(slice.state.version, 1)
    XCTAssertEqual(slice.state.hasChanges(\.self), true)
    XCTAssertNotNil(weakBaseSlice)

    wrapper.empty()

    XCTAssertEqual(slice.state.primitive, 1)
    XCTAssertEqual(slice.state.version, 1) // with memoized, version not changed
    XCTAssertEqual(slice.state.hasChanges(\.self), true)
    XCTAssertNotNil(weakBaseSlice)

    wrapper.increment()

    XCTAssertEqual(slice.state.primitive, 2)
    XCTAssertEqual(slice.state.version, 2)
    XCTAssertEqual(slice.state.hasChanges(\.self), true)
    XCTAssertNotNil(weakBaseSlice)

    slice = nil

    XCTAssertNil(weakSlice)
    XCTAssertNil(weakBaseSlice)

  }

  final class Resource {
    deinit {
      print("d")
    }
  }
}
