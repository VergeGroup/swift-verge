import XCTest
import Verge

final class BindingDerivedTests: XCTestCase {

  func testBinding() {

    let source = DemoStore()

    let binding = source.bindingDerived(
      get: .select(\.count),
      set: { source, new in
        source.count = new
      })

    XCTAssertEqual(binding.state, 0)
    
    binding.wrappedValue = 2

    XCTAssertEqual(binding.state, 2)
    XCTAssertEqual(source.state.count, 2)

  }

  func testBinding_abstract() {

    let source = DemoStore()

    let binding: some StoreDriverType<Int> = source.bindingDerived(
      get: .select(\.count),
      set: { source, new in
        source.count = new
      })

    XCTAssertEqual(binding.state, 0)

    binding.commit {
      $0 = 2
    }

    XCTAssertEqual(binding.state, 2)
    XCTAssertEqual(source.state.count, 2)

    source.commit {
      $0.count += 1
    }

    XCTAssertEqual(binding.state, 3)

  }

  func testBinding_upstreamChanged() {
    let source = DemoStore()

    let binding = source.bindingDerived(
      get: .select(\.count),
      set: { source, new in
        source.count = new
      })

    source.commit {
      $0.count += 1
    }

    XCTAssertEqual(source.state.count, 1)

    XCTAssertEqual(binding.state, 1)


  }

}
