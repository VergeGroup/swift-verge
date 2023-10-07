import Verge
import XCTest

final class StoreAndDerivedTests: XCTestCase {

  @MainActor
  func test() async {

    let store = Store<_, Never>(initialState: DemoState())

    let derived = store.derived(.select(\.name))

    for i in 0..<1000 {

      await withBackground {
        store.commit {
          $0.name = "\(i)"
        }
      }

      XCTAssertEqual(derived.state.primitive, "\(i)")
    }

  }

}

/**
 Performs the given task in background
 */
public nonisolated func withBackground<Return: Sendable>(
  _ thunk: @escaping @Sendable () async throws -> Return
) async rethrows -> Return {

  // for now we will keep this until Swift6.
  assert(Thread.isMainThread == false)

  // here is the background as it's nonisolated
  // to inherit current actor context, use @_unsafeInheritExecutor

  // thunk closure runs on the background as it's sendable
  // if it's not sendable, inherit current actor context but it's already background.
  // @_inheritActorContext makes closure runs on current actor context even if it's sendable.
  return try await thunk()
}
