import XCTest
import Verge

final class BindingDerivedTests: XCTestCase {

  func testBinding() {

    let source = DemoStore()

    let binding = source.bindingDerived(
      get: .map { $0.count },
      set: { source, new in
        source.count = new
      })

    binding.primitiveValue = 2

    XCTAssertEqual(binding.state.primitive, 2)
    XCTAssertEqual(source.primitiveState.count, 2)

  }

  func testBinding_abstract() {

    let source = DemoStore()

    let binding: some DispatcherType<Int> = source.bindingDerived(
      get: .map { $0.count },
      set: { source, new in
        source.count = new
      })

    XCTAssertEqual(binding.state.previous?.primitive, nil)
    XCTAssertEqual(binding.state.primitive, 0)

    binding.commit {
      $0.replace(with: 2)
    }

    XCTAssertEqual(binding.state.previous?.primitive, 0)
    XCTAssertEqual(binding.state.primitive, 2)

    XCTAssertEqual(source.primitiveState.count, 2)

  }

}
